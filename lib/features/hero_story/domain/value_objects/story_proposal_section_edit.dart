import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Hero edit of one narrative section within a Story Proposal (SB.12).
///
/// Does not carry sourceResponseIds or contentOrigin — those remain
/// system-managed and are preserved by [StoryProposal.editHeroContent].
final class StoryProposalSectionEdit extends ValueObject {
  StoryProposalSectionEdit({
    required this.sectionId,
    this.content,
  }) {
    final trimmed = content?.trim();
    if (content != null && (trimmed == null || trimmed.isEmpty)) {
      throw ArgumentError(
        'Section edit content cannot be blank when provided; '
        'pass null to clear content.',
      );
    }
  }

  final StoryProposalSectionId sectionId;

  /// Replacement content. Null clears section content (empty section).
  final String? content;

  @override
  List<Object?> get equalityProps => [sectionId, content];
}
