import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/reject_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';

/// Explicit Hero rejection of a [StoryProposal] (SB.12).
///
/// Flow: load → [StoryProposal.reject] → save.
/// Rejected proposals remain persisted. Never creates a Story.
final class RejectStoryProposalUseCase
    implements UseCase<RejectStoryProposalRequest, StoryProposal> {
  const RejectStoryProposalUseCase({
    required StoryProposalRepository proposalRepository,
  }) : _proposalRepository = proposalRepository;

  final StoryProposalRepository _proposalRepository;

  @override
  Future<Result<StoryProposal>> execute(
    RejectStoryProposalRequest request,
  ) async {
    try {
      final proposal = await _proposalRepository.findById(request.proposalId);
      if (proposal == null) {
        return Failure(
          'Story Proposal ${request.proposalId} not found.',
        );
      }

      final rejected = proposal.reject(at: request.rejectedAt);
      await _proposalRepository.save(rejected);
      return Success(rejected);
    } catch (e) {
      return Failure('Failed to reject Story Proposal: $e');
    }
  }
}
