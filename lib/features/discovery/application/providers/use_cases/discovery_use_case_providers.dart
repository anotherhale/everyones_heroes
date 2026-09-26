import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/discovery/application/providers/current_local_user_id_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/discovery_profile_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/services/influence_theme_resolver_provider.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';

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

final resolveNarrativeThemesUseCaseProvider =
    Provider<ResolveNarrativeThemesUseCase>((ref) {
  return ResolveNarrativeThemesUseCase(
    repository: ref.watch(discoveryProfileRepositoryProvider),
    resolver: ref.watch(influenceThemeResolverProvider),
  );
});
