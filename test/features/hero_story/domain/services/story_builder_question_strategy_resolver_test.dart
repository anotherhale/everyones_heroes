import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/ai_story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy_resolver.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/unsupported_ai_story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_builder_coach_adapter.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = DefaultStoryBuilderQuestionStrategyResolver();

  test('guided mode resolves to deterministic strategy', () {
    final strategy = resolver.resolve(StoryBuilderMode.guided);
    expect(strategy, isA<DeterministicStoryBuilderQuestionStrategy>());
  });

  test('ai mode resolves to AiStoryBuilderQuestionStrategy when wired', () {
    final resolver = DefaultStoryBuilderQuestionStrategyResolver(
      aiStrategy: AiStoryBuilderQuestionStrategy(
        coach: InMemoryStoryBuilderCoachAdapter(),
      ),
    );
    final strategy = resolver.resolve(StoryBuilderMode.ai);
    expect(strategy, isA<AiStoryBuilderQuestionStrategy>());
    expect(strategy, isNot(isA<DeterministicStoryBuilderQuestionStrategy>()));
  });

  test('default resolver keeps unsupported AI stub until composition injects coach', () {
    const resolver = DefaultStoryBuilderQuestionStrategyResolver();
    expect(
      resolver.resolve(StoryBuilderMode.ai),
      isA<UnsupportedAiStoryBuilderQuestionStrategy>(),
    );
  });

  test('unsupported AI strategy does not invent prompts', () async {
    final session = StoryBuilderSession.create(
      id: StoryBuilderSessionId.generate(),
      heroId: HeroId.generate(),
      mode: StoryBuilderMode.ai,
    );
    final strategy = const UnsupportedAiStoryBuilderQuestionStrategy();
    expect(
      () => strategy.nextPrompt(session),
      throwsA(isA<UnsupportedError>()),
    );
    expect(strategy.isQuestioningComplete(session), isFalse);
  });
}
