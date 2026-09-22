import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Applies Hero content edits to a persisted [StoryProposal] (SB.12).
///
/// Flow: load → [StoryProposal.editHeroContent] → save.
/// Preserves provenance; may invalidate stale approval.
/// Never mutates the Story Builder session; never creates a Story.
final class EditStoryProposalUseCase
    implements UseCase<EditStoryProposalRequest, StoryProposal> {
  const EditStoryProposalUseCase({
    required StoryProposalRepository proposalRepository,
    StoryBuilderSessionRepository? sessionRepository,
  })  : _proposalRepository = proposalRepository,
        _sessionRepository = sessionRepository;

  final StoryProposalRepository _proposalRepository;
  final StoryBuilderSessionRepository? _sessionRepository;

  @override
  Future<Result<StoryProposal>> execute(
    EditStoryProposalRequest request,
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
      final sessionBefore =
          sessionRepo == null ? null : await sessionRepo.findById(sessionId);
      final responseCountBefore = sessionBefore?.responses.length;
      final responseTextsBefore = sessionBefore == null
          ? null
          : [for (final r in sessionBefore.responses) r.text];
      final statusBefore = sessionBefore?.status;
      final storyIdBefore = sessionBefore?.storyId;

      final edited = proposal.editHeroContent(
        title: request.title,
        updateTitle: request.updateTitle,
        clearTitle: request.clearTitle,
        summary: request.summary,
        updateSummary: request.updateSummary,
        clearSummary: request.clearSummary,
        sectionEdits: request.sectionEdits,
        editedAt: request.editedAt,
      );

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
            'Story Proposal edit must not mutate the Story Builder session.',
          );
        }
      }

      await _proposalRepository.save(edited);
      return Success(edited);
    } catch (e) {
      return Failure('Failed to edit Story Proposal: $e');
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
