import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/archive_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_detail_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_owned_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/load_owned_story_media_use_case.dart';

/// Owner Story application providers (HS.10).
///
/// Separated from discoverability-gated experience providers.
final listHeroOwnedStoriesUseCaseProvider =
    Provider<ListHeroOwnedStoriesUseCase>((ref) {
      return ListHeroOwnedStoriesUseCase(
        storyRepository: ref.watch(storyRepositoryProvider),
        heroRepository: ref.watch(heroRepositoryProvider),
      );
    });

final getOwnedStoryDetailUseCaseProvider = Provider<GetOwnedStoryDetailUseCase>(
  (ref) {
    return GetOwnedStoryDetailUseCase(
      storyRepository: ref.watch(storyRepositoryProvider),
      heroRepository: ref.watch(heroRepositoryProvider),
    );
  },
);

final loadOwnedStoryMediaUseCaseProvider = Provider<LoadOwnedStoryMediaUseCase>(
  (ref) {
    return LoadOwnedStoryMediaUseCase(
      storyRepository: ref.watch(storyRepositoryProvider),
      heroRepository: ref.watch(heroRepositoryProvider),
      mediaStorage: ref.watch(storyMediaStoragePortProvider),
    );
  },
);

final archiveStoryUseCaseProvider = Provider<ArchiveStoryUseCase>((ref) {
  return ArchiveStoryUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});
