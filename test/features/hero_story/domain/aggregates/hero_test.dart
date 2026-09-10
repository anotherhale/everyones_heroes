import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
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

    test('attachPublishedStory is idempotent', () {
      final hero = createHero();
      final storyId = StoryId.generate();

      hero.attachPublishedStory(storyId);
      hero.attachPublishedStory(storyId);

      expect(hero.publishedStoryIds, [storyId]);
    });
  });
}
