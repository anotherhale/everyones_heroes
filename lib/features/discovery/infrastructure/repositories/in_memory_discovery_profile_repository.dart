import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';

import '../../domain/aggregates/discovery_profile.dart';
import '../../domain/repositories/discovery_profile_repository.dart';

final class InMemoryDiscoveryProfileRepository
    implements DiscoveryProfileRepository {
  final Map<String, DiscoveryProfile> _profiles = {};

  @override
  Future<DiscoveryProfile?> findById(DiscoveryProfileId id) async {
    return _profiles[id.value];
  }

  @override
  Future<void> save(DiscoveryProfile profile) async {
    _profiles[profile.id.value] = profile;
  }
}
