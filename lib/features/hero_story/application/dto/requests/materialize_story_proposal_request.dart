import 'package:everyonesheroes/core/ids/story_proposal_id.dart';

final class MaterializeStoryProposalRequest {
  const MaterializeStoryProposalRequest({
    required this.proposalId,
    this.materializedAt,
  });

  final StoryProposalId proposalId;
  final DateTime? materializedAt;
}
