import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/discovery/domain/repositories/discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';

/// Process-lifetime DiscoveryProfile store (D.1).
///
/// ## Persistence decision
///
/// Flutter local Journey / Reflection remain in-memory for the transitional
/// offline path. DiscoveryProfile follows the same pattern: a shared Riverpod
/// singleton for the app session. Durable DiscoveryProfile persistence belongs
/// to the platform D.1 plan and is intentionally deferred here so we do not
/// invent a parallel file store ahead of Identity + platform authority.
final discoveryProfileRepositoryProvider =
    Provider<DiscoveryProfileRepository>((ref) {
  return InMemoryDiscoveryProfileRepository();
});
