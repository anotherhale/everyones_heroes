import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/build_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_understanding_builder.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_proposal_builder.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_structure_builder.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Builds a reviewable [StoryProposal] from a canonical Story Builder session.
///
/// Flow: load session → SB.4 structure → deterministic Understanding → proposal.
/// Never creates a [Story], never mutates the session, never calls AI.
final class BuildStoryProposalUseCase
    implements UseCase<BuildStoryProposalRequest, StoryProposal> {
  const BuildStoryProposalUseCase({
    required this._sessionRepository,
    required this._proposalRepository,
    this._structureBuilder = const DeterministicStoryStructureBuilder(),
    this._understandingBuilder =
        const DeterministicStoryBuilderUnderstandingBuilder(),
    this._proposalBuilder = const DeterministicStoryProposalBuilder(),
  });

  final StoryBuilderSessionRepository _sessionRepository;
  final StoryProposalRepository _proposalRepository;
  final DeterministicStoryStructureBuilder _structureBuilder;
  final DeterministicStoryBuilderUnderstandingBuilder _understandingBuilder;
  final DeterministicStoryProposalBuilder _proposalBuilder;

  @override
  Future<Result<StoryProposal>> execute(
    BuildStoryProposalRequest request,
  ) async {
    try {
      final session = await _sessionRepository.findById(request.sessionId);
      if (session == null) {
        return Failure(
          'Story Builder session ${request.sessionId} not found.',
        );
      }

      if (session.status == StoryBuilderSessionStatus.abandoned) {
        return Failure(
          'Cannot build a proposal for an abandoned Story Builder session.',
        );
      }

      final answered = session.responses.where((r) => !r.skipped).toList();
      if (answered.isEmpty) {
        return Failure(
          'Story Builder session ${session.id} has no answered material '
          'for a proposal.',
        );
      }

      final purposeBefore = session.intent.purpose;
      final themesBefore = List.of(session.intent.themes);
      final responseCountBefore = session.responses.length;
      final responseTextsBefore = [
        for (final r in session.responses) r.text,
      ];
      final storyIdBefore = session.storyId;
      final statusBefore = session.status;

      final structure = _structureBuilder.build(session);
      final createdAt = request.createdAt ?? DateTime.now();
      final understanding = _understandingBuilder.build(
        session: session,
        structure: structure,
        analyzedAt: createdAt,
      );
      final proposal = _proposalBuilder.build(
        session: session,
        structure: structure,
        understanding: understanding,
        createdAt: createdAt,
      );

      if (session.intent.purpose != purposeBefore ||
          !_sameList(session.intent.themes, themesBefore) ||
          session.responses.length != responseCountBefore ||
          !_sameList(
            [for (final r in session.responses) r.text],
            responseTextsBefore,
          ) ||
          session.storyId != storyIdBefore ||
          session.status != statusBefore) {
        return Failure(
          'Story Proposal construction must not mutate the Story Builder session.',
        );
      }

      await _proposalRepository.save(proposal);
      return Success(proposal);
    } catch (e) {
      return Failure('Failed to build Story Proposal: $e');
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
