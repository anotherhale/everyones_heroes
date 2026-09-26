import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/discovery/application/dto/responses/inspiring_hero_summary.dart';
import 'package:everyonesheroes/features/discovery/application/providers/current_local_user_id_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/discovery_profile_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/influence_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/services/influence_theme_resolver_provider.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_inspiring_hero_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/list_influences_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/list_inspiring_heroes_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/remove_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/remove_inspiring_hero_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/select_influences_use_case.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/influence.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';

final ensureCurrentDiscoveryProfileUseCaseProvider =
    Provider<EnsureCurrentDiscoveryProfileUseCase>((ref) {
  return EnsureCurrentDiscoveryProfileUseCase(
    repository: ref.watch(discoveryProfileRepositoryProvider),
    currentUserId: ref.watch(currentLocalUserIdProvider),
  );
});

/// Ensures the current user's DiscoveryProfile exists for this app session.
final currentDiscoveryProfileProvider = FutureProvider<DiscoveryProfile>((
  ref,
) async {
  return ref.watch(ensureCurrentDiscoveryProfileUseCaseProvider).execute();
});

final addInfluenceUseCaseProvider = Provider<AddInfluenceUseCase>((ref) {
  return AddInfluenceUseCase(
    repository: ref.watch(discoveryProfileRepositoryProvider),
  );
});

final removeInfluenceUseCaseProvider = Provider<RemoveInfluenceUseCase>((ref) {
  return RemoveInfluenceUseCase(
    ensureCurrentDiscoveryProfile: ref.watch(
      ensureCurrentDiscoveryProfileUseCaseProvider,
    ),
    repository: ref.watch(discoveryProfileRepositoryProvider),
    resolveNarrativeThemes: ref.watch(resolveNarrativeThemesUseCaseProvider),
  );
});

final resolveNarrativeThemesUseCaseProvider =
    Provider<ResolveNarrativeThemesUseCase>((ref) {
  return ResolveNarrativeThemesUseCase(
    repository: ref.watch(discoveryProfileRepositoryProvider),
    resolver: ref.watch(influenceThemeResolverProvider),
  );
});

final listInfluencesUseCaseProvider = Provider<ListInfluencesUseCase>((ref) {
  return ListInfluencesUseCase(
    repository: ref.watch(influenceRepositoryProvider),
  );
});

/// Curated Influence catalog for Discovery selection (D.3).
final curatedInfluencesProvider = FutureProvider<List<Influence>>((ref) {
  return ref.watch(listInfluencesUseCaseProvider).execute();
});

final selectInfluencesUseCaseProvider = Provider<SelectInfluencesUseCase>((
  ref,
) {
  return SelectInfluencesUseCase(
    ensureCurrentDiscoveryProfile: ref.watch(
      ensureCurrentDiscoveryProfileUseCaseProvider,
    ),
    addInfluence: ref.watch(addInfluenceUseCaseProvider),
    resolveNarrativeThemes: ref.watch(resolveNarrativeThemesUseCaseProvider),
    influenceRepository: ref.watch(influenceRepositoryProvider),
  );
});

final addInspiringHeroUseCaseProvider = Provider<AddInspiringHeroUseCase>((
  ref,
) {
  return AddInspiringHeroUseCase(
    ensureCurrentDiscoveryProfile: ref.watch(
      ensureCurrentDiscoveryProfileUseCaseProvider,
    ),
    repository: ref.watch(discoveryProfileRepositoryProvider),
  );
});

final removeInspiringHeroUseCaseProvider =
    Provider<RemoveInspiringHeroUseCase>((ref) {
  return RemoveInspiringHeroUseCase(
    ensureCurrentDiscoveryProfile: ref.watch(
      ensureCurrentDiscoveryProfileUseCaseProvider,
    ),
    repository: ref.watch(discoveryProfileRepositoryProvider),
  );
});

final listInspiringHeroesUseCaseProvider =
    Provider<ListInspiringHeroesUseCase>((ref) {
  return ListInspiringHeroesUseCase(
    ensureCurrentDiscoveryProfile: ref.watch(
      ensureCurrentDiscoveryProfileUseCaseProvider,
    ),
    heroRepository: ref.watch(heroRepositoryProvider),
  );
});

/// Discoverable inspiring Heroes for the current seeker (D.11).
///
/// Unresolved / undiscoverable IDs are filtered at read time and remain on
/// DiscoveryProfile.
final inspiringHeroesProvider =
    FutureProvider<List<InspiringHeroSummary>>((ref) {
  return ref.watch(listInspiringHeroesUseCaseProvider).execute();
});

/// Whether [heroId] is currently in the seeker's inspiringHeroIds (D.11).
final isHeroInspiringMeProvider = Provider.family<AsyncValue<bool>, String>((
  ref,
  heroId,
) {
  final profileAsync = ref.watch(currentDiscoveryProfileProvider);
  return profileAsync.whenData(
    (profile) => profile.containsInspiringHero(HeroId(heroId)),
  );
});
