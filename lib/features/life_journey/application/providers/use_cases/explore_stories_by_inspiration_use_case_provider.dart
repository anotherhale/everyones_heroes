import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/discovery/application/providers/repositories/narrative_theme_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/life_journey/application/models/inspiration_story_exploration.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/explore_stories_by_inspiration_use_case.dart';

final exploreStoriesByInspirationUseCaseProvider =
    Provider<ExploreStoriesByInspirationUseCase>((ref) {
  return DefaultExploreStoriesByInspirationUseCase(
    ensureCurrentDiscoveryProfile: ref.watch(
      ensureCurrentDiscoveryProfileUseCaseProvider,
    ),
    discoverStories: ref.watch(discoverStoriesUseCaseProvider),
    narrativeThemeRepository: ref.watch(narrativeThemeRepositoryProvider),
  );
});

/// Inspiration-grounded Story exploration for the Discover tab (D.7).
///
/// Watches [currentDiscoveryProfileProvider] so add/remove Influence
/// invalidation refreshes exploration results.
final inspirationGroundedStoriesProvider =
    FutureProvider.autoDispose<InspirationStoryExploration>((ref) async {
  // Establish dependency so Influence save invalidation refreshes this.
  await ref.watch(currentDiscoveryProfileProvider.future);
  return ref.watch(exploreStoriesByInspirationUseCaseProvider).execute();
});
