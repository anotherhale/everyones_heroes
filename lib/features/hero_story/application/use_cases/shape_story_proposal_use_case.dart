import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/shape_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_shaper.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Deterministically shapes a persisted [StoryProposal] (SB.10).
///
/// Flow: load proposal → shape via [StoryShaperPort] → persist shaped proposal.
/// Never creates a [Story], never mutates the Story Builder session, never
/// calls AI.
final class ShapeStoryProposalUseCase
    implements UseCase<ShapeStoryProposalRequest, StoryProposal> {
  const ShapeStoryProposalUseCase({
    required this._proposalRepository,
    this._sessionRepository,
    this._shaper = const DeterministicStoryShaper(),
  });

  final StoryProposalRepository _proposalRepository;

  /// Optional — when provided, used only to assert the session is unchanged.
  final StoryBuilderSessionRepository? _sessionRepository;

  final StoryShaperPort _shaper;

  @override
  Future<Result<StoryProposal>> execute(
    ShapeStoryProposalRequest request,
  ) async {
    try {
      final proposal = await _proposalRepository.findById(request.proposalId);
      if (proposal == null) {
        return Failure(
          'Story Proposal ${request.proposalId} not found.',
        );
      }

      final sessionId = proposal.sessionId;
      final sessionRepo = _sessionRepository;
      final sessionBefore = sessionRepo == null
          ? null
          : await sessionRepo.findById(sessionId);
      final responseCountBefore = sessionBefore?.responses.length;
      final responseTextsBefore = sessionBefore == null
          ? null
          : [for (final r in sessionBefore.responses) r.text];
      final statusBefore = sessionBefore?.status;
      final storyIdBefore = sessionBefore?.storyId;

      // Snapshot source fields to assert immutability of the loaded value.
      final sourceNarrative = proposal.narrative;
      final sourceSectionContents = [
        for (final s in proposal.sections) s.content,
      ];
      final sourceLifecycle = proposal.lifecycle;
      final sourceProcessingVersion = proposal.provenance.processingVersion;

      final StoryProposal shaped;
      final shaper = _shaper;
      if (shaper is DeterministicStoryShaper) {
        shaped = shaper.shapeSync(proposal, shapedAt: request.shapedAt);
      } else {
        shaped = await shaper.shape(proposal);
      }

      // Source proposal must remain unchanged (value object / caller snapshot).
      if (proposal.narrative != sourceNarrative ||
          proposal.lifecycle != sourceLifecycle ||
          proposal.provenance.processingVersion != sourceProcessingVersion) {
        return Failure(
          'Story Proposal shaping must not mutate the source proposal.',
        );
      }
      for (var i = 0; i < proposal.sections.length; i++) {
        if (proposal.sections[i].content != sourceSectionContents[i]) {
          return Failure(
            'Story Proposal shaping must not mutate the source proposal.',
          );
        }
      }

      if (sessionBefore != null && sessionRepo != null) {
        final sessionAfter = await sessionRepo.findById(sessionId);
        if (sessionAfter == null ||
            sessionAfter.responses.length != responseCountBefore ||
            !_sameList(
              [for (final r in sessionAfter.responses) r.text],
              responseTextsBefore!,
            ) ||
            sessionAfter.status != statusBefore ||
            sessionAfter.storyId != storyIdBefore) {
          return Failure(
            'Story Proposal shaping must not mutate the Story Builder session.',
          );
        }
      }

      await _proposalRepository.save(shaped);
      return Success(shaped);
    } catch (e) {
      return Failure('Failed to shape Story Proposal: $e');
    }
  }

  static bool _sameList(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
