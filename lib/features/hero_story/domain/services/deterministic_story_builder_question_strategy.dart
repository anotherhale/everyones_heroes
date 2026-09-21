import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_catalog.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';

/// Guided / deterministic question strategy (SB.3).
///
/// Uses [DeterministicStoryBuilderCatalog]. No AI, network, proxy, or credits.
/// Intent purpose/themes are not used to branch prompts in SB.3.
final class DeterministicStoryBuilderQuestionStrategy
    implements StoryBuilderQuestionStrategy {
  const DeterministicStoryBuilderQuestionStrategy();

  @override
  Future<StoryBuilderPrompt?> nextPrompt(StoryBuilderSession session) async {
    for (final prompt in DeterministicStoryBuilderCatalog.prompts) {
      final hasResponse = session.responses.any((r) => r.promptId == prompt.id);
      if (!hasResponse) {
        return prompt;
      }
    }
    return null;
  }

  @override
  bool isQuestioningComplete(StoryBuilderSession session) {
    for (final prompt in DeterministicStoryBuilderCatalog.prompts) {
      final hasResponse = session.responses.any((r) => r.promptId == prompt.id);
      if (!hasResponse) {
        return false;
      }
    }
    return true;
  }
}
