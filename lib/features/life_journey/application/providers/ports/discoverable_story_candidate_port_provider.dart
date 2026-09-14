import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/discover_stories_candidate_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/discoverable_story_candidate_port.dart';

/// Composition-root wiring: Life Journey port → Hero & Story Discover* adapter.
final discoverableStoryCandidatePortProvider =
    Provider<DiscoverableStoryCandidatePort>((ref) {
      return DiscoverStoriesCandidateAdapter(
        discoverStoriesUseCase: ref.watch(discoverStoriesUseCaseProvider),
      );
    });
