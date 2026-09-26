import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';

import '../aggregates/discovery_profile.dart';

abstract interface class DiscoveryProfileRepository {
  Future<DiscoveryProfile?> findById(DiscoveryProfileId id);

  /// Returns the DiscoveryProfile for [userId], if one exists.
  ///
  /// D.1: one profile per local user is the intended application invariant;
  /// repository implementations should not invent Identity binding.
  Future<DiscoveryProfile?> findByUserId(UserId userId);

  Future<void> save(DiscoveryProfile profile);
}
