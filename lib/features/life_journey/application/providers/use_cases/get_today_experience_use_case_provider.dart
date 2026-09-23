import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/providers/context/current_journey_context_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/ports/discoverable_story_candidate_port_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/journey_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/services/experience_selection_service_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/resolve_adaptive_discovery_signals_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/submit_reflection_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/services/adaptive_experience_composer.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/platform_get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/today_experience_cache.dart';

final todayExperienceCacheProvider = Provider<TodayExperienceCache>((ref) {
  return TodayExperienceCache();
});

/// Today's Experience authority:
///
/// * Platform client configured (`EH_PLATFORM_URL` / platform H.2 mode)
///   → platform `GET /v1/experiences/today`
/// * otherwise → transitional local UI.3 + HS.8 selection (tests / offline demos)
///
/// Platform mode never falls back to local selection on a successful path.
final getTodayExperienceUseCaseProvider =
    Provider<GetTodayExperienceUseCase>((ref) {
  final client = ref.watch(ehPlatformClientProvider);
  if (client != null) {
    return PlatformGetTodayExperienceUseCase(
      client: client,
      cache: ref.read(todayExperienceCacheProvider),
    );
  }

  final selectionService = ref.read(experienceSelectionServiceProvider);

  return DefaultGetTodayExperienceUseCase(
    journeyRepository: ref.read(journeyRepositoryProvider),
    currentJourneyContext: ref.read(currentJourneyContextProvider),
    experienceSelectionService: selectionService,
    resolveAdaptiveDiscoverySignals: ref.read(
      resolveAdaptiveDiscoverySignalsUseCaseProvider,
    ),
    storyCandidatePort: ref.read(discoverableStoryCandidatePortProvider),
    composer: AdaptiveExperienceComposer(
      reflectionSelectionService: selectionService,
    ),
  );
});
