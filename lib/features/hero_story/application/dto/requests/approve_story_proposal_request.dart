import 'package:everyonesheroes/core/ids/story_proposal_id.dart';

/// Request for explicit Hero approval of a Story Proposal (SB.12).
final class ApproveStoryProposalRequest {
  const ApproveStoryProposalRequest({
    required this.proposalId,
    this.approvedAt,
  });

  final StoryProposalId proposalId;
  final DateTime? approvedAt;
}
