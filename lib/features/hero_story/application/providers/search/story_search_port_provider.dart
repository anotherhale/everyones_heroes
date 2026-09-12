import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_search_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';

final storySearchPortProvider = Provider<StorySearchPort>((ref) {
  return InMemoryStorySearchAdapter(ref.watch(storyRepositoryProvider));
});
