import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';

/// Explicit unavailable stub for [StoryBuilderMode.ai].
///
/// Production SB.7 wiring uses [AiStoryBuilderQuestionStrategy]. This stub
/// remains for tests and intentional "AI disabled" composition.
final class UnsupportedAiStoryBuilderQuestionStrategy
    implements StoryBuilderQuestionStrategy {
  const UnsupportedAiStoryBuilderQuestionStrategy();

  static const String unavailableMessage =
      'AI Story Builder is not available. '
      'Choose Guided Story Builder, or retry when the AI Story Coach is ready.';

  @override
  Future<StoryBuilderPrompt?> nextPrompt(StoryBuilderSession session) {
    throw UnsupportedError(unavailableMessage);
  }

  @override
  bool isQuestioningComplete(StoryBuilderSession session) => false;
}
