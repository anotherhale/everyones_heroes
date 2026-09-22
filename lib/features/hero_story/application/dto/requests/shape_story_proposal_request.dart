import 'package:everyonesheroes/core/ids/story_proposal_id.dart';

/// Request to deterministically shape an existing [StoryProposal] (SB.10).
final class ShapeStoryProposalRequest {
  const ShapeStoryProposalRequest({
    required this.proposalId,
    this.shapedAt,
  });

  final StoryProposalId proposalId;

  /// Optional fixed timestamp for deterministic tests.
  final DateTime? shapedAt;
}
