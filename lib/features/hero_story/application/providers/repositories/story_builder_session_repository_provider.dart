import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';

/// Default in-memory repository for unit/application tests.
///
/// Production durable composition ([AppCompositionRoot]) overrides this with
/// [FileStoryBuilderSessionRepository] via [HeroStoryDurablePersistence].
final storyBuilderSessionRepositoryProvider =
    Provider<StoryBuilderSessionRepository>((ref) {
      return InMemoryStoryBuilderSessionRepository();
    });
