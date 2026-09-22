import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section_edit.dart';

/// Request to apply Hero edits to a Story Proposal (SB.12).
final class EditStoryProposalRequest {
  const EditStoryProposalRequest({
    required this.proposalId,
    this.title,
    this.updateTitle = false,
    this.clearTitle = false,
    this.summary,
    this.updateSummary = false,
    this.clearSummary = false,
    this.sectionEdits = const [],
    this.editedAt,
  });

  final StoryProposalId proposalId;
  final String? title;
  final bool updateTitle;
  final bool clearTitle;
  final String? summary;
  final bool updateSummary;
  final bool clearSummary;
  final List<StoryProposalSectionEdit> sectionEdits;
  final DateTime? editedAt;
}
