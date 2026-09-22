import 'package:everyonesheroes/core/ids/story_proposal_id.dart';

/// Request to begin Hero revision of an accepted/rejected proposal (SB.12).
final class BeginStoryProposalRevisionRequest {
  const BeginStoryProposalRevisionRequest({
    required this.proposalId,
    this.revisedAt,
  });

  final StoryProposalId proposalId;
  final DateTime? revisedAt;
}
