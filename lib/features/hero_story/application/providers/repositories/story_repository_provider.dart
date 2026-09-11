import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return InMemoryStoryRepository();
});
