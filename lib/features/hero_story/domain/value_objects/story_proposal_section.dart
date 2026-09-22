import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';

/// One ordered narrative section in a [StoryProposal] (SB.9).
///
/// Reuses [StoryBuilderNarrativeRole] (SB.3/SB.4). Content is typically
/// Hero-authored response text; skipped/empty slots stay distinguishable.
final class StoryProposalSection extends ValueObject {
  StoryProposalSection({
    required this.id,
    required this.narrativeRole,
    required this.order,
    required this.contentOrigin,
    Iterable<StoryBuilderResponseId>? sourceResponseIds,
    this.content,
    this.wasSkipped = false,
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

  bool get hasContent => content != null;

  bool get hasSourceMaterial =>
      sourceResponseIds.isNotEmpty && !wasSkipped;

  bool get isEmpty => sourceResponseIds.isEmpty && !wasSkipped;

  @override
  List<Object?> get equalityProps => [
    id,
    narrativeRole,
    order,
    contentOrigin,
    content,
    wasSkipped,
    ...sourceResponseIds,
  ];
}
