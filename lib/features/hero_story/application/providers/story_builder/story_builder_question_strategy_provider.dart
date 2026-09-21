import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_builder_coach_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/ai_story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy_resolver.dart';

/// Default guided strategy (SB.3). Prefer [storyBuilderQuestionStrategyResolverProvider]
/// when advancing a session so [StoryBuilderMode] is respected.
final storyBuilderQuestionStrategyProvider =
    Provider<StoryBuilderQuestionStrategy>((ref) {
      return const DeterministicStoryBuilderQuestionStrategy();
    });

/// Mode → strategy resolution (SB.6 / SB.7).
///
/// Guided → deterministic. AI → [AiStoryBuilderQuestionStrategy] via coach port.
final storyBuilderQuestionStrategyResolverProvider =
    Provider<StoryBuilderQuestionStrategyResolver>((ref) {
      return DefaultStoryBuilderQuestionStrategyResolver(
        aiStrategy: AiStoryBuilderQuestionStrategy(
          coach: ref.watch(storyBuilderCoachPortProvider),
        ),
      );
    });
