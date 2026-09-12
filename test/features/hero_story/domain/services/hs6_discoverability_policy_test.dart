import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');

  group('StoryDiscoverabilityPolicy', () {
    Story published({
      StoryVisibility visibility = StoryVisibility.public,
    }) {
      final story = Story.create(
        id: StoryId.generate(),
        heroId: HeroId.generate(),
        title: StoryTitle('Policy Story'),
        narrative: StoryNarrative('Published narrative for policy checks.'),
        originalLanguage: english,
      );
      story.updateConsent(
        story.consent
            .grantProcessing(DateTime.utc(2026, 1, 1))
            .grantPublication(DateTime.utc(2026, 1, 1)),
      );
      story
        ..submit()
        ..markReadyForReview()
        ..approve()
        ..changeVisibility(visibility)
        ..publish();
      return story;
    }

    test('allows public and community published stories', () {
      expect(
        StoryDiscoverabilityPolicy.isDiscoverable(
          published(visibility: StoryVisibility.public),
        ),
        isTrue,
      );
      expect(
        StoryDiscoverabilityPolicy.isDiscoverable(
          published(visibility: StoryVisibility.community),
        ),
        isTrue,
      );
    });

    test('rejects unlisted published stories', () {
      expect(
        StoryDiscoverabilityPolicy.isDiscoverable(
          published(visibility: StoryVisibility.unlisted),
        ),
        isFalse,
      );
    });

    test('rejects drafts and provisional narratives', () {
      final draft = Story.create(
        id: StoryId.generate(),
        heroId: HeroId.generate(),
        title: StoryTitle('Draft'),
        narrative: StoryNarrative('Draft narrative text.'),
        originalLanguage: english,
      );
      expect(StoryDiscoverabilityPolicy.isDiscoverable(draft), isFalse);

      final provisional = Story.createFromCapture(
        id: StoryId.generate(),
        heroId: HeroId.generate(),
        originalLanguage: english,
      );
      expect(StoryDiscoverabilityPolicy.isDiscoverable(provisional), isFalse);
    });
  });

  group('HeroDiscoverabilityPolicy', () {
    test('allows public/community active heroes only', () {
      final publicHero = Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(displayName: 'Public'),
        visibility: HeroVisibility.public,
      );
      final privateHero = Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(displayName: 'Private'),
        visibility: HeroVisibility.private,
      );
      final unlistedHero = Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(displayName: 'Unlisted'),
        visibility: HeroVisibility.unlisted,
      );
      final archived = Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(displayName: 'Archived'),
        visibility: HeroVisibility.public,
      )..archive();

      expect(HeroDiscoverabilityPolicy.isDiscoverable(publicHero), isTrue);
      expect(HeroDiscoverabilityPolicy.isDiscoverable(privateHero), isFalse);
      expect(HeroDiscoverabilityPolicy.isDiscoverable(unlistedHero), isFalse);
      expect(HeroDiscoverabilityPolicy.isDiscoverable(archived), isFalse);
    });
  });
}
