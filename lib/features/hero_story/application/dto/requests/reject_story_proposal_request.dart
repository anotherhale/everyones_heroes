import 'package:everyonesheroes/core/ids/story_proposal_id.dart';

/// Request for explicit Hero rejection of a Story Proposal (SB.12).
final class RejectStoryProposalRequest {
  const RejectStoryProposalRequest({
    required this.proposalId,
    this.rejectedAt,
  });

  final StoryProposalId proposalId;
  final DateTime? rejectedAt;
}
