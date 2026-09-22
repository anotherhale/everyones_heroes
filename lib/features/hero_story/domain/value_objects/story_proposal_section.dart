import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';

/// One ordered narrative section in a [StoryProposal] (SB.9 / SB.12).
///
/// Reuses [StoryBuilderNarrativeRole] (SB.3/SB.4). Content is typically
/// Hero-authored response text; skipped/empty slots stay distinguishable.
///
/// [contentOrigin] records where the material originated. Hero edits during
/// review are tracked separately via [heroEdited] / [contentBeforeHeroEdit]
/// so AI-derived provenance is never overwritten.
final class StoryProposalSection extends ValueObject {
  StoryProposalSection({
    required this.id,
    required this.narrativeRole,
    required this.order,
    required this.contentOrigin,
    Iterable<StoryBuilderResponseId>? sourceResponseIds,
    this.content,
    this.wasSkipped = false,
    this.heroEdited = false,
    this.heroEditedAt,
    this.contentBeforeHeroEdit,
  }) : sourceResponseIds = List.unmodifiable(
         sourceResponseIds?.toList() ?? const <StoryBuilderResponseId>[],
       ) {
    if (order < 0) {
      throw ArgumentError('Section order cannot be negative.');
    }
    if (wasSkipped && this.sourceResponseIds.isEmpty) {
      throw ArgumentError(
        'Skipped sections must retain skip response IDs for provenance.',
      );
    }
    if (wasSkipped && content != null) {
      throw ArgumentError('Skipped sections cannot carry proposal content.');
    }
    if (content != null &&
        contentOrigin == StoryProposalContentOrigin.heroAuthored &&
        this.sourceResponseIds.isEmpty) {
      throw ArgumentError(
        'Hero-authored section content requires sourceResponseIds.',
      );
    }
    if (heroEditedAt != null && !heroEdited) {
      throw ArgumentError(
        'heroEditedAt requires heroEdited to be true.',
      );
    }
    final baseline = contentBeforeHeroEdit?.trim();
    if (contentBeforeHeroEdit != null &&
        (baseline == null || baseline.isEmpty)) {
      throw ArgumentError(
        'contentBeforeHeroEdit cannot be blank when provided.',
      );
    }
    if (contentBeforeHeroEdit != null && !heroEdited) {
      throw ArgumentError(
        'contentBeforeHeroEdit requires heroEdited to be true.',
      );
    }
  }

  final StoryProposalSectionId id;
  final StoryBuilderNarrativeRole narrativeRole;
  final int order;
  final StoryProposalContentOrigin contentOrigin;

  /// Verbatim Hero response text when answered; null when skipped or empty.
  final String? content;

  final List<StoryBuilderResponseId> sourceResponseIds;

  /// True when the Hero explicitly skipped the corresponding Builder prompt.
  final bool wasSkipped;

  /// True when the Hero edited this section during proposal review (SB.12).
  ///
  /// Does not change [contentOrigin] — origin remains heroAuthored or derived.
  final bool heroEdited;

  /// When the Hero last edited this section's content during review.
  final DateTime? heroEditedAt;

  /// Section content as it existed before the Hero's first review edit.
  ///
  /// Preserves AI/deterministic wording for comparison without mutating origin.
  final String? contentBeforeHeroEdit;

  bool get hasContent => content != null;

  bool get hasSourceMaterial =>
      sourceResponseIds.isNotEmpty && !wasSkipped;

  bool get isEmpty => sourceResponseIds.isEmpty && !wasSkipped;

  /// Returns a copy with Hero-edited content; provenance fields are preserved.
  StoryProposalSection withHeroEditedContent({
    required String? newContent,
    required DateTime editedAt,
  }) {
    if (wasSkipped) {
      throw StateError('Cannot edit content of a skipped section.');
    }
    final trimmed = newContent?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    final previous = content;
    final baseline = contentBeforeHeroEdit ??
        (previous != null && previous.trim().isNotEmpty ? previous : null);

    return StoryProposalSection(
      id: id,
      narrativeRole: narrativeRole,
      order: order,
      contentOrigin: contentOrigin,
      sourceResponseIds: sourceResponseIds,
      content: normalized,
      wasSkipped: wasSkipped,
      heroEdited: true,
      heroEditedAt: editedAt,
      contentBeforeHeroEdit: baseline,
    );
  }

  @override
  List<Object?> get equalityProps => [
    id,
    narrativeRole,
    order,
    contentOrigin,
    content,
    wasSkipped,
    heroEdited,
    heroEditedAt,
    contentBeforeHeroEdit,
    ...sourceResponseIds,
  ];
}
