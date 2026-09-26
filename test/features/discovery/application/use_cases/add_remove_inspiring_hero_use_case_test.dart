import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_inspiring_hero_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/remove_inspiring_hero_use_case.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';

void main() {
  late InMemoryDiscoveryProfileRepository profileRepository;
  late EnsureCurrentDiscoveryProfileUseCase ensure;
  late AddInspiringHeroUseCase addInspiringHero;
  late RemoveInspiringHeroUseCase removeInspiringHero;
  final userId = UserId('dev-user');
  final heroA = HeroId('hero-a');
  final heroB = HeroId('hero-b');

  setUp(() {
    profileRepository = InMemoryDiscoveryProfileRepository();
    ensure = EnsureCurrentDiscoveryProfileUseCase(
      repository: profileRepository,
      currentUserId: userId,
    );
    addInspiringHero = AddInspiringHeroUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      repository: profileRepository,
    );
    removeInspiringHero = RemoveInspiringHeroUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      repository: profileRepository,
    );
  });

  group('AddInspiringHeroUseCase', () {
    test('adds inspiring Hero and saves profile', () async {
      final profile = await addInspiringHero.execute(heroA);

      expect(profile.containsInspiringHero(heroA), isTrue);

      final persisted = await profileRepository.findByUserId(userId);
      expect(persisted, isNotNull);
      expect(persisted!.containsInspiringHero(heroA), isTrue);
    });

    test('creates profile via EnsureCurrent when missing', () async {
      expect(await profileRepository.findByUserId(userId), isNull);

      final profile = await addInspiringHero.execute(heroA);

      expect(profile.userId, userId);
      expect(profile.containsInspiringHero(heroA), isTrue);
    });

    test('preserves unrelated profile state', () async {
      final existing = DiscoveryProfile(
        id: DiscoveryProfileId.generate(),
        userId: userId,
        influenceIds: [const InfluenceId('influence-1')],
      );
      await profileRepository.save(existing);

      final profile = await addInspiringHero.execute(heroA);

      expect(profile.containsInfluence(const InfluenceId('influence-1')), isTrue);
      expect(profile.containsInspiringHero(heroA), isTrue);
      expect(profile.narrativeThemeIds, isEmpty);
    });

    test('duplicate add is idempotent and preserves other heroes', () async {
      await addInspiringHero.execute(heroA);
      await addInspiringHero.execute(heroB);
      final profile = await addInspiringHero.execute(heroA);

      expect(profile.inspiringHeroIds, hasLength(2));
      expect(profile.containsInspiringHero(heroA), isTrue);
      expect(profile.containsInspiringHero(heroB), isTrue);
    });
  });

  group('RemoveInspiringHeroUseCase', () {
    test('removes inspiring Hero and saves profile', () async {
      await addInspiringHero.execute(heroA);
      await addInspiringHero.execute(heroB);

      final profile = await removeInspiringHero.execute(heroA);

      expect(profile.containsInspiringHero(heroA), isFalse);
      expect(profile.containsInspiringHero(heroB), isTrue);

      final persisted = await profileRepository.findByUserId(userId);
      expect(persisted!.containsInspiringHero(heroA), isFalse);
      expect(persisted.containsInspiringHero(heroB), isTrue);
    });

    test('removing absent HeroId is safe', () async {
      await addInspiringHero.execute(heroA);

      final profile = await removeInspiringHero.execute(heroB);

      expect(profile.containsInspiringHero(heroA), isTrue);
      expect(profile.containsInspiringHero(heroB), isFalse);
    });

    test('preserves Influences when removing inspiring Hero', () async {
      final existing = DiscoveryProfile(
        id: DiscoveryProfileId.generate(),
        userId: userId,
        influenceIds: [const InfluenceId('influence-1')],
        inspiringHeroIds: [heroA],
      );
      await profileRepository.save(existing);

      final profile = await removeInspiringHero.execute(heroA);

      expect(profile.containsInfluence(const InfluenceId('influence-1')), isTrue);
      expect(profile.inspiringHeroIds, isEmpty);
    });
  });
}
