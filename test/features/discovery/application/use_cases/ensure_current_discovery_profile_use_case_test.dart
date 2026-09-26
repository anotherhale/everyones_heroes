import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/discovery/discovery_profile_fixture.dart';

void main() {
  group('EnsureCurrentDiscoveryProfileUseCase', () {
    late InMemoryDiscoveryProfileRepository repository;
    late UserId currentUserId;
    late EnsureCurrentDiscoveryProfileUseCase useCase;

    setUp(() {
      repository = InMemoryDiscoveryProfileRepository();
      currentUserId = UserId('dev-user');
      useCase = EnsureCurrentDiscoveryProfileUseCase(
        repository: repository,
        currentUserId: currentUserId,
      );
    });

    test('creates an empty profile for the current user when missing', () async {
      final profile = await useCase.execute();

      expect(profile.userId, currentUserId);
      expect(profile.influenceIds, isEmpty);
      expect(profile.narrativeThemeIds, isEmpty);

      final loaded = await repository.findByUserId(currentUserId);
      expect(loaded!.id, profile.id);
    });

    test('returns the existing profile without creating another', () async {
      final existing = DiscoveryProfileFixture.create(
        id: DiscoveryProfileId('profile-existing'),
        userId: currentUserId,
      );
      await repository.save(existing);

      final profile = await useCase.execute();

      expect(profile.id, existing.id);
      expect(await repository.findByUserId(currentUserId), existing);
    });

    test('can ensure a profile for an explicit userId override', () async {
      final other = UserId('other-user');

      final profile = await useCase.execute(userId: other);

      expect(profile.userId, other);
      expect(await repository.findByUserId(currentUserId), isNull);
      expect(await repository.findByUserId(other), isNotNull);
    });
  });
}
