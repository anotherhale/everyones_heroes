import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';

import '../aggregates/discovery_profile.dart';

abstract interface class DiscoveryProfileRepository {
  Future<DiscoveryProfile?> findById(DiscoveryProfileId id);

  Future<void> save(DiscoveryProfile profile);
}
