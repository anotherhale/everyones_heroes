import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/story_understanding_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_understanding_repository.dart';

final storyUnderstandingRepositoryProvider =
    Provider<StoryUnderstandingRepository>((ref) {
  return InMemoryStoryUnderstandingRepository();
});
