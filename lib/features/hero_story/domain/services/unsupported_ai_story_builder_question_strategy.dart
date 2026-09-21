import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';

/// Explicit SB.6 placeholder for [StoryBuilderMode.ai].
///
/// Does not invoke AI, credits, or network. SB.7 replaces this with a real
/// adaptive strategy. Callers must treat [UnsupportedError] as "AI unavailable".
final class UnsupportedAiStoryBuilderQuestionStrategy
    implements StoryBuilderQuestionStrategy {
  const UnsupportedAiStoryBuilderQuestionStrategy();

  static const String unavailableMessage =
      'AI Story Builder is not available yet. '
      'Choose Guided Story Builder, or continue when adaptive coaching ships.';

  @override
  Future<StoryBuilderPrompt?> nextPrompt(StoryBuilderSession session) {
    throw UnsupportedError(unavailableMessage);
  }

  @override
  bool isQuestioningComplete(StoryBuilderSession session) => false;
}
