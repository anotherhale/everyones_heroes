import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/discovery/application/ports/repository_discovery_profile_theme_source.dart';
import 'package:everyonesheroes/features/discovery/application/providers/current_local_user_id_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/discovery_profile_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/discovery_profile_theme_source.dart';

/// Wires DiscoveryProfile themes into Life Journey adaptive signal resolution.
final discoveryProfileThemeSourceProvider =
    Provider<DiscoveryProfileThemeSource>((ref) {
  return RepositoryDiscoveryProfileThemeSource(
    discoveryProfileRepository: ref.watch(discoveryProfileRepositoryProvider),
    currentUserId: ref.watch(currentLocalUserIdProvider),
  );
});
