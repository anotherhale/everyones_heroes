import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/deterministic_story_structure_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';

/// Derived deterministic narrative structure for a [StoryBuilderSession].
///
/// Not a Story aggregate. Not persisted — regenerate from session responses.
/// Does not rewrite Hero-authored material.
final class DeterministicStoryStructure extends ValueObject {
  DeterministicStoryStructure({
    required this.sessionId,
    required this.intent,
    required Iterable<DeterministicStoryStructureSection> sections,
  }) : sections = List.unmodifiable(sections.toList()) {
    if (this.sections.isEmpty) {
      throw ArgumentError('Structure requires at least one section slot.');
    }
    for (var i = 0; i < this.sections.length; i++) {
      if (this.sections[i].order != i) {
        throw ArgumentError(
          'Structure sections must be contiguous from order 0.',
        );
      }
    }
  }

  final StoryBuilderSessionId sessionId;

  /// Session intent at derivation time (purpose/themes metadata only).
  final StoryBuilderIntent intent;

  final List<DeterministicStoryStructureSection> sections;

  int get populatedSectionCount =>
      sections.where((s) => s.hasSourceMaterial).length;

  int get skippedSectionCount => sections.where((s) => s.wasSkipped).length;

  int get emptySectionCount => sections.where((s) => s.isEmpty).length;

  int get sectionCount => sections.length;

  DeterministicStoryStructureSection? sectionForRole(
    StoryBuilderNarrativeRole narrativeRole,
  ) {
    for (final section in sections) {
      if (section.narrativeRole == narrativeRole) {
        return section;
      }
    }
    return null;
  }

  @override
  List<Object?> get equalityProps => [
    sessionId,
    intent,
    ...sections,
  ];
}
