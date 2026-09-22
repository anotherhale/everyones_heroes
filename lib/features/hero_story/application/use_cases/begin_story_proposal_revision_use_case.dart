import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/begin_story_proposal_revision_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Begins Hero revision of an accepted/rejected [StoryProposal] (SB.12).
///
/// Invalidates prior approval so the Hero must explicitly approve again.
final class BeginStoryProposalRevisionUseCase
    implements UseCase<BeginStoryProposalRevisionRequest, StoryProposal> {
  const BeginStoryProposalRevisionUseCase({
    required this._proposalRepository,
  });

  final StoryProposalRepository _proposalRepository;

  @override
  Future<Result<StoryProposal>> execute(
    BeginStoryProposalRevisionRequest request,
  ) async {
    try {
      final proposal = await _proposalRepository.findById(request.proposalId);
      if (proposal == null) {
        return Failure(
          'Story Proposal ${request.proposalId} not found.',
        );
      }

      final revised = proposal.beginHeroRevision(at: request.revisedAt);
      await _proposalRepository.save(revised);
      return Success(revised);
    } catch (e) {
      return Failure('Failed to begin Story Proposal revision: $e');
    }
  }
}
