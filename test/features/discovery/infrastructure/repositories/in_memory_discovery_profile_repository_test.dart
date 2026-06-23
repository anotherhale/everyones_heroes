import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';

import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';

void main() {
  group('InMemoryDiscoveryProfileRepository', () {
    test('saves and retrieves profile', () async {
      final repository = InMemoryDiscoveryProfileRepository();

      final profile = DiscoveryProfile(
        id: DiscoveryProfileId('profile-1'),
        userId: UserId('user-1'),
      );

      await repository.save(profile);

      final result = await repository.findById(profile.id);

      expect(result, same(profile));
    });

    test('returns null when missing', () async {
      final repository = InMemoryDiscoveryProfileRepository();

      final result = await repository.findById(DiscoveryProfileId('missing'));

      expect(result, isNull);
    });
  });
}
