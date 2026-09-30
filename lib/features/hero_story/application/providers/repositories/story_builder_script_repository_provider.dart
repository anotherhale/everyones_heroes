import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_script_repository.dart';

/// Default in-memory script repository.
///
/// App composition overrides with [FileStoryBuilderScriptRepository] via
/// [HeroStoryDurablePersistence].
final storyBuilderScriptRepositoryProvider =
    Provider<StoryBuilderScriptRepository>((ref) {
  return InMemoryStoryBuilderScriptRepository();
});
