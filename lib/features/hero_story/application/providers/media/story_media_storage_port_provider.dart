import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';

/// Shared in-memory Story media store for local/dev and HS.7 consumption.
final storyMediaStoragePortProvider = Provider<StoryMediaStoragePort>((ref) {
  return InMemoryStoryMediaStorageAdapter();
});
