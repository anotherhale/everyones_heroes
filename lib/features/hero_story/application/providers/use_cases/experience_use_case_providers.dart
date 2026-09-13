import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/begin_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/consume_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_hero_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/load_story_media_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/resolve_playable_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/create_reflection_use_case_provider.dart';

final getStoryExperienceUseCaseProvider = Provider<GetStoryExperienceUseCase>((
  ref,
) {
  return GetStoryExperienceUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
  );
});

final getHeroExperienceUseCaseProvider = Provider<GetHeroExperienceUseCase>((
  ref,
) {
  return GetHeroExperienceUseCase(
    heroRepository: ref.watch(heroRepositoryProvider),
  );
});

final listHeroStoriesUseCaseProvider = Provider<ListHeroStoriesUseCase>((ref) {
  return ListHeroStoriesUseCase(
    discoverStoriesUseCase: ref.watch(discoverStoriesUseCaseProvider),
  );
});

final resolvePlayableRepresentationUseCaseProvider =
    Provider<ResolvePlayableRepresentationUseCase>((ref) {
      return ResolvePlayableRepresentationUseCase(
        storyRepository: ref.watch(storyRepositoryProvider),
        heroRepository: ref.watch(heroRepositoryProvider),
      );
    });

final loadStoryMediaUseCaseProvider = Provider<LoadStoryMediaUseCase>((ref) {
  return LoadStoryMediaUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
    mediaStorage: ref.watch(storyMediaStoragePortProvider),
  );
});

final beginStoryExperienceUseCaseProvider =
    Provider<BeginStoryExperienceUseCase>((ref) {
      return BeginStoryExperienceUseCase(
        getStoryExperienceUseCase: ref.watch(getStoryExperienceUseCaseProvider),
        resolvePlayableRepresentationUseCase: ref.watch(
          resolvePlayableRepresentationUseCaseProvider,
        ),
      );
    });

final consumeStoryExperienceUseCaseProvider =
    Provider<ConsumeStoryExperienceUseCase>((ref) {
      return ConsumeStoryExperienceUseCase(
        getStoryExperienceUseCase: ref.watch(getStoryExperienceUseCaseProvider),
        storyRepository: ref.watch(storyRepositoryProvider),
        heroRepository: ref.watch(heroRepositoryProvider),
      );
    });

final startStoryReflectionUseCaseProvider =
    Provider<StartStoryReflectionUseCase>((ref) {
      return StartStoryReflectionUseCase(
        getStoryExperienceUseCase: ref.watch(getStoryExperienceUseCaseProvider),
        createReflectionUseCase: ref.watch(createReflectionUseCaseProvider),
      );
    });
