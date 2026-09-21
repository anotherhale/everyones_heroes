import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy_resolver.dart';

/// Default guided strategy (SB.3). Prefer [storyBuilderQuestionStrategyResolverProvider]
/// when advancing a session so [StoryBuilderMode] is respected.
final storyBuilderQuestionStrategyProvider =
    Provider<StoryBuilderQuestionStrategy>((ref) {
      return const DeterministicStoryBuilderQuestionStrategy();
    });

/// Mode → strategy resolution (SB.6).
///
/// Guided → deterministic. AI → explicit unsupported placeholder until SB.7.
final storyBuilderQuestionStrategyResolverProvider =
    Provider<StoryBuilderQuestionStrategyResolver>((ref) {
      return const DefaultStoryBuilderQuestionStrategyResolver();
    });
