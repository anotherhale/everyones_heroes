import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy.dart';

/// Default production strategy is deterministic / guided (SB.3).
///
/// AI strategy wiring belongs to SB.7 — do not replace this default with AI.
final storyBuilderQuestionStrategyProvider =
    Provider<StoryBuilderQuestionStrategy>((ref) {
      return const DeterministicStoryBuilderQuestionStrategy();
    });
