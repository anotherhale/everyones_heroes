import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_experience_plan_repository.dart';

/// Default in-memory repository for unit/application tests.
///
/// Production durable composition overrides with
/// [FileStoryExperiencePlanRepository].
final storyExperiencePlanRepositoryProvider =
    Provider<StoryExperiencePlanRepository>((ref) {
  return InMemoryStoryExperiencePlanRepository();
});
