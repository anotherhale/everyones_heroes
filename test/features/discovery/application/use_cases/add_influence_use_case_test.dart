import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';

import 'package:everyonesheroes/features/discovery/application/use_cases/add_influence_use_case.dart';

import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';

import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';

void main() {
  group('AddInfluenceUseCase', () {
    test('adds influence to profile', () async {
      final repository = InMemoryDiscoveryProfileRepository();

      final profile = DiscoveryProfile(
        id: DiscoveryProfileId('profile-1'),
        userId: UserId('user-1'),
      );

      await repository.save(profile);

      final useCase = AddInfluenceUseCase(repository: repository);

      final influenceId = InfluenceId('rocky');

      await useCase.execute(profileId: profile.id, influenceId: influenceId);

      final updated = await repository.findById(profile.id);

      expect(updated!.containsInfluence(influenceId), isTrue);
    });

    test('throws when profile does not exist', () async {
      final repository = InMemoryDiscoveryProfileRepository();

      final useCase = AddInfluenceUseCase(repository: repository);

      expect(
        () => useCase.execute(
          profileId: DiscoveryProfileId('missing'),
          influenceId: InfluenceId('rocky'),
        ),
        throwsStateError,
      );
    });
  });
}
