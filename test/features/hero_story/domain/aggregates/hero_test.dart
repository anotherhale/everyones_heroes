import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  group('Hero', () {
    Hero createHero() {
      return Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Jordan Hale',
          biography: 'Served as a firefighter for 18 years.',
          experienceAreas: const ['First Response', 'Leadership'],
          languages: [LanguageCode('en')],
        ),
        identityUserId: UserId.generate(),
      );
    }

    test('create raises HeroCreated', () {
      final hero = createHero();
      final events = hero.pullDomainEvents();
      expectEventRaised<HeroCreated>(events);
      expectEventCount(events, 1);
    });

    test('stores factual profile without psychological claims API', () {
      final hero = createHero();
      expect(hero.profile.displayName, 'Jordan Hale');
      expect(hero.profile.experienceAreas, contains('First Response'));
      expect(hero.status, HeroStatus.active);
    });

    test('updateProfile raises HeroProfileUpdated', () {
      final hero = createHero();
      hero.pullDomainEvents();

      hero.updateProfile(
        hero.profile.copyWith(biography: 'Volunteer mentor.'),
      );

      final events = hero.pullDomainEvents();
      expectEventRaised<HeroProfileUpdated>(events);
    });

    test('cannot update archived hero', () {
      final hero = createHero();
      hero.archive();

      expect(
        () => hero.updateProfile(hero.profile.copyWith(displayName: 'Other')),
        throwsStateError,
      );
    });

    test('defaults to private visibility', () {
      final hero = createHero();
      expect(hero.visibility, HeroVisibility.private);
    });

    test('changeVisibility updates visibility while active', () {
      final hero = createHero();
      hero.pullDomainEvents();

      hero.changeVisibility(HeroVisibility.public);
      expect(hero.visibility, HeroVisibility.public);

      hero.changeVisibility(HeroVisibility.community);
      expect(hero.visibility, HeroVisibility.community);

      hero.changeVisibility(HeroVisibility.private);
      expect(hero.visibility, HeroVisibility.private);

      // Visibility changes do not raise domain events today.
      expect(hero.pullDomainEvents(), isEmpty);
    });

    test('cannot changeVisibility on archived hero', () {
      final hero = createHero();
      hero.archive();

      expect(
        () => hero.changeVisibility(HeroVisibility.public),
        throwsStateError,
      );
      expect(hero.visibility, HeroVisibility.private);
    });
  });
}
