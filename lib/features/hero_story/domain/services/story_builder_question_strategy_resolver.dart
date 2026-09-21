import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/unsupported_ai_story_builder_question_strategy.dart';

/// Resolves [StoryBuilderMode] → [StoryBuilderQuestionStrategy].
///
/// Application orchestration (e.g. Advance) should not hard-code a single
/// strategy; mode on the session is authoritative.
abstract interface class StoryBuilderQuestionStrategyResolver {
  StoryBuilderQuestionStrategy resolve(StoryBuilderMode mode);
}

/// Default resolution:
/// - guided → deterministic catalog strategy
/// - ai → [AiStoryBuilderQuestionStrategy] (SB.7)
///
/// Inject [aiStrategy] from composition (coach port wiring). Tests may pass
/// [UnsupportedAiStoryBuilderQuestionStrategy] explicitly.
final class DefaultStoryBuilderQuestionStrategyResolver
    implements StoryBuilderQuestionStrategyResolver {
  const DefaultStoryBuilderQuestionStrategyResolver({
    this.guidedStrategy = const DeterministicStoryBuilderQuestionStrategy(),
    this.aiStrategy = const UnsupportedAiStoryBuilderQuestionStrategy(),
  });

  final StoryBuilderQuestionStrategy guidedStrategy;
  final StoryBuilderQuestionStrategy aiStrategy;

  @override
  StoryBuilderQuestionStrategy resolve(StoryBuilderMode mode) {
    return switch (mode) {
      StoryBuilderMode.guided => guidedStrategy,
      StoryBuilderMode.ai => aiStrategy,
    };
  }
}
