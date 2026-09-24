import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_experience_planner_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/captured_story_reading_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_story_experience_plan_use_case.dart';

final generateStoryExperiencePlanUseCaseProvider =
    Provider<GenerateStoryExperiencePlanUseCase>((ref) {
  return GenerateStoryExperiencePlanUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    readingRepository: ref.watch(capturedStoryReadingRepositoryProvider),
    planner: ref.watch(storyExperiencePlannerPortProvider),
    planRepository: ref.watch(storyExperiencePlanRepositoryProvider),
  );
});
