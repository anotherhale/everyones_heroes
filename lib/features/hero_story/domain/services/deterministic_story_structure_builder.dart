import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_catalog.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/deterministic_story_structure.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/deterministic_story_structure_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';

/// Builds a [DeterministicStoryStructure] from a [StoryBuilderSession].
///
/// Pure mapping: catalog narrative roles → sections referencing response IDs.
/// No AI, no prose generation, no Story creation.
final class DeterministicStoryStructureBuilder {
  const DeterministicStoryStructureBuilder();

  DeterministicStoryStructure build(StoryBuilderSession session) {
    final sections = <DeterministicStoryStructureSection>[];

    for (final prompt in DeterministicStoryBuilderCatalog.prompts) {
      final role = prompt.narrativeRole;
      if (role == null) {
        throw StateError(
          'Catalog prompt ${prompt.id} is missing a narrative role.',
        );
      }

      final response = _responseForPrompt(session, prompt.id);
      if (response == null) {
        sections.add(
          DeterministicStoryStructureSection(
            narrativeRole: role,
            order: prompt.ordinal,
            promptId: prompt.id,
          ),
        );
        continue;
      }

      sections.add(
        DeterministicStoryStructureSection(
          narrativeRole: role,
          order: prompt.ordinal,
          promptId: prompt.id,
          sourceResponseIds: [response.id],
          wasSkipped: response.skipped,
        ),
      );
    }

    return DeterministicStoryStructure(
      sessionId: session.id,
      intent: session.intent,
      sections: sections,
    );
  }

  StoryBuilderResponse? _responseForPrompt(
    StoryBuilderSession session,
    StoryBuilderPromptId promptId,
  ) {
    for (final response in session.responses) {
      if (response.promptId == promptId) {
        return response;
      }
    }
    return null;
  }
}
