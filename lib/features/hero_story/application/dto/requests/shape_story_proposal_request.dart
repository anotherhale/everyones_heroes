import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_shaper_mode.dart';

/// Request to shape an existing [StoryProposal] (SB.10 / SB.11).
final class ShapeStoryProposalRequest {
  const ShapeStoryProposalRequest({
    required this.proposalId,
    this.mode = StoryShaperMode.deterministic,
    this.shapedAt,
  });

  final StoryProposalId proposalId;

  /// Deterministic (SB.10) or AI (SB.11). Independent of interview mode.
  final StoryShaperMode mode;

  /// Optional fixed timestamp for deterministic tests.
  final DateTime? shapedAt;
}
