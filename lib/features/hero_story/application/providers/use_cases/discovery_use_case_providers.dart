import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/search/hero_search_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/search/story_search_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/browse_stories_by_catalog_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_heroes_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_discovery_summary_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/search_heroes_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/search_stories_use_case.dart';

final searchStoriesUseCaseProvider = Provider<SearchStoriesUseCase>((ref) {
  return SearchStoriesUseCase(
    storySearchPort: ref.watch(storySearchPortProvider),
  );
});

final searchHeroesUseCaseProvider = Provider<SearchHeroesUseCase>((ref) {
  return SearchHeroesUseCase(
    heroSearchPort: ref.watch(heroSearchPortProvider),
  );
});

final discoverStoriesUseCaseProvider = Provider<DiscoverStoriesUseCase>((ref) {
  return DiscoverStoriesUseCase(
    storySearchPort: ref.watch(storySearchPortProvider),
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
  );
});

final discoverHeroesUseCaseProvider = Provider<DiscoverHeroesUseCase>((ref) {
  return DiscoverHeroesUseCase(
    heroSearchPort: ref.watch(heroSearchPortProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
  );
});

final browseStoriesByCatalogUseCaseProvider =
    Provider<BrowseStoriesByCatalogUseCase>((ref) {
      return BrowseStoriesByCatalogUseCase(
        discoverStoriesUseCase: ref.watch(discoverStoriesUseCaseProvider),
      );
    });

final getStoryDiscoverySummaryUseCaseProvider =
    Provider<GetStoryDiscoverySummaryUseCase>((ref) {
      return GetStoryDiscoverySummaryUseCase(
        storyRepository: ref.watch(storyRepositoryProvider),
        heroRepository: ref.watch(heroRepositoryProvider),
      );
    });
