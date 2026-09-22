import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Explicit Hero approval of a [StoryProposal] (SB.12).
///
/// Flow: load → [StoryProposal.approve] → save.
/// Never creates a Story, never publishes, never catalogs.
/// On save failure the use case returns Failure — callers must not claim success.
final class ApproveStoryProposalUseCase
    implements UseCase<ApproveStoryProposalRequest, StoryProposal> {
  const ApproveStoryProposalUseCase({
    required StoryProposalRepository proposalRepository,
  }) : _proposalRepository = proposalRepository;

  final StoryProposalRepository _proposalRepository;

  @override
  Future<Result<StoryProposal>> execute(
    ApproveStoryProposalRequest request,
  ) async {
    try {
      final proposal = await _proposalRepository.findById(request.proposalId);
      if (proposal == null) {
        return Failure(
          'Story Proposal ${request.proposalId} not found.',
        );
      }

      final approved = proposal.approve(at: request.approvedAt);
      await _proposalRepository.save(approved);
      return Success(approved);
    } catch (e) {
      return Failure('Failed to approve Story Proposal: $e');
    }
  }
}
