import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';

/// One ordered section in a deterministic Story Builder structure.
///
/// References Hero-authored [StoryBuilderResponse] IDs — does not copy text.
final class DeterministicStoryStructureSection extends ValueObject {
  DeterministicStoryStructureSection({
    required this.narrativeRole,
    required this.order,
    required this.promptId,
    Iterable<StoryBuilderResponseId>? sourceResponseIds,
    this.wasSkipped = false,
  }) : sourceResponseIds = List.unmodifiable(
         sourceResponseIds?.toList() ?? const <StoryBuilderResponseId>[],
       ) {
    if (order < 0) {
      throw ArgumentError('Section order cannot be negative.');
    }
    if (wasSkipped && this.sourceResponseIds.isEmpty) {
      throw ArgumentError(
        'Skipped sections must reference the skip response for provenance.',
      );
    }
  }

  final StoryBuilderNarrativeRole narrativeRole;
  final int order;
  final StoryBuilderPromptId promptId;
  final List<StoryBuilderResponseId> sourceResponseIds;

  /// True when the Hero explicitly skipped this prompt.
  final bool wasSkipped;

  /// True when there is answered (non-skip) source material.
  bool get hasSourceMaterial =>
      sourceResponseIds.isNotEmpty && !wasSkipped;

  bool get isEmpty => sourceResponseIds.isEmpty && !wasSkipped;

  @override
  List<Object?> get equalityProps => [
    narrativeRole,
    order,
    promptId,
    wasSkipped,
    ...sourceResponseIds,
  ];
}
