import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/discovery/user_discovery_fixture.dart';
import '../../../../fixtures/discovery_profile_fixture.dart';
import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';

void main() {
  group('InMemoryDiscoveryProfileRepository', () {
    late InMemoryDiscoveryProfileRepository repository;

    setUp(() {
      repository = InMemoryDiscoveryProfileRepository();
    });

    test('returns null when profile does not exist', () async {
      final result = await repository.findById(DiscoveryProfileId.generate());

      expect(result, isNull);
    });

    test('saves and retrieves a profile', () async {
      final profile = DiscoveryProfileFixture.create();

      await repository.save(profile);

      final loaded = await repository.findById(profile.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, equals(profile.id));
      expect(loaded.userId, equals(profile.userId));
      expect(loaded.influenceIds, equals(profile.influenceIds));
      expect(loaded.narrativeThemeIds, equals(profile.narrativeThemeIds));
      expect(loaded.discoveries, hasLength(0));
      expect(loaded.preferences, hasLength(0));
    });

    test('saving an updated profile persists changes', () async {
      final profile = DiscoveryProfileFixture.create();

      await repository.save(profile);

      profile.addDiscovery(UserDiscoveryFixture.favoriteHero());

      await repository.save(profile);

      final loaded = await repository.findById(profile.id);

      expect(loaded, isNotNull);
      expect(loaded!.discoveries, hasLength(1));
      expect(loaded.discoveries.single.value, equals('Rocky Balboa'));
    });
  });
}
