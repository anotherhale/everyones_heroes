import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_inspiring_hero_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/list_inspiring_heroes_use_case.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';

void main() {
  late InMemoryDiscoveryProfileRepository profileRepository;
  late InMemoryHeroRepository heroRepository;
  late EnsureCurrentDiscoveryProfileUseCase ensure;
  late AddInspiringHeroUseCase addInspiringHero;
  late ListInspiringHeroesUseCase listInspiringHeroes;
  final userId = UserId('dev-user');
  final english = LanguageCode('en');

  setUp(() {
    profileRepository = InMemoryDiscoveryProfileRepository();
    heroRepository = InMemoryHeroRepository();
    ensure = EnsureCurrentDiscoveryProfileUseCase(
      repository: profileRepository,
      currentUserId: userId,
    );
    addInspiringHero = AddInspiringHeroUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      repository: profileRepository,
    );
    listInspiringHeroes = ListInspiringHeroesUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      heroRepository: heroRepository,
    );
  });

  Future<Hero> saveHero({
    required String name,
    HeroVisibility visibility = HeroVisibility.public,
  }) async {
    final hero = Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: name,
        biography: 'Bio for $name',
        languages: [english],
      ),
      visibility: visibility,
    );
    await heroRepository.save(hero);
    return hero;
  }

  group('ListInspiringHeroesUseCase', () {
    test('resolves discoverable inspiring Heroes', () async {
      final hero = await saveHero(name: 'Alex Rivera');
      await addInspiringHero.execute(hero.id);

      final results = await listInspiringHeroes.execute();

      expect(results, hasLength(1));
      expect(results.single.heroId, hero.id);
      expect(results.single.displayName, 'Alex Rivera');
      expect(results.single.biography, 'Bio for Alex Rivera');
    });

    test('omits undiscoverable Heroes without removing from profile', () async {
      final publicHero = await saveHero(name: 'Public Hero');
      final privateHero = await saveHero(
        name: 'Private Hero',
        visibility: HeroVisibility.private,
      );
      await addInspiringHero.execute(publicHero.id);
      await addInspiringHero.execute(privateHero.id);

      final results = await listInspiringHeroes.execute();

      expect(results, hasLength(1));
      expect(results.single.heroId, publicHero.id);

      final profile = await profileRepository.findByUserId(userId);
      expect(profile!.inspiringHeroIds, hasLength(2));
      expect(profile.containsInspiringHero(privateHero.id), isTrue);
    });

    test('omits unresolved HeroIds without crashing or mutating profile',
        () async {
      final missingId = HeroId('missing-hero');
      final publicHero = await saveHero(name: 'Present Hero');
      await addInspiringHero.execute(missingId);
      await addInspiringHero.execute(publicHero.id);

      final results = await listInspiringHeroes.execute();

      expect(results, hasLength(1));
      expect(results.single.heroId, publicHero.id);

      final profile = await profileRepository.findByUserId(userId);
      expect(profile!.containsInspiringHero(missingId), isTrue);
      expect(profile.inspiringHeroIds, hasLength(2));
    });

    test('returns empty list when no inspiring Heroes', () async {
      final results = await listInspiringHeroes.execute();
      expect(results, isEmpty);
    });
  });
}
