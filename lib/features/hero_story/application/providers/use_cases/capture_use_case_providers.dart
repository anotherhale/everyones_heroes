import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/cancel_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_owned_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/submit_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';

/// Shared capture completion store (must be shared by Complete + Cancel).
///
/// Default is in-memory for unit tests. Production composition overrides with
/// a durable [FileCaptureCompletionStore] (HS.9).
final captureCompletionStoreProvider = Provider<CaptureCompletionStore>((ref) {
  return InMemoryCaptureCompletionStore();
});

final completeStoryCaptureUseCaseProvider =
    Provider<CompleteStoryCaptureUseCase>((ref) {
      return CompleteStoryCaptureUseCase(
        storyRepository: ref.watch(storyRepositoryProvider),
        heroRepository: ref.watch(heroRepositoryProvider),
        mediaStorage: ref.watch(storyMediaStoragePortProvider),
        eventBus: ref.watch(eventBusProvider),
        completionStore: ref.watch(captureCompletionStoreProvider),
      );
    });

final cancelStoryCaptureUseCaseProvider = Provider<CancelStoryCaptureUseCase>((
  ref,
) {
  return CancelStoryCaptureUseCase(
    mediaStorage: ref.watch(storyMediaStoragePortProvider),
    completionStore: ref.watch(captureCompletionStoreProvider),
  );
});

final updateStoryConsentUseCaseProvider = Provider<UpdateStoryConsentUseCase>((
  ref,
) {
  return UpdateStoryConsentUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final createHeroUseCaseProvider = Provider<CreateHeroUseCase>((ref) {
  return CreateHeroUseCase(
    heroRepository: ref.watch(heroRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final submitStoryUseCaseProvider = Provider<SubmitStoryUseCase>((ref) {
  return SubmitStoryUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final listHeroOwnedStoriesUseCaseProvider =
    Provider<ListHeroOwnedStoriesUseCase>((ref) {
      return ListHeroOwnedStoriesUseCase(
        storyRepository: ref.watch(storyRepositoryProvider),
        heroRepository: ref.watch(heroRepositoryProvider),
      );
    });
