import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/discover_stories_candidate_adapter.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../life_journey/builders/behavioral_evidence_builder.dart';

void main() {
  final courage = NarrativeThemeId('courage');

  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late DiscoverStoriesCandidateAdapter adapter;

  setUp(() {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    adapter = DiscoverStoriesCandidateAdapter(
      discoverStoriesUseCase: DiscoverStoriesUseCase(
        storySearchPort: InMemoryStorySearchAdapter(stories),
        storyRepository: stories,
        heroRepository: heroes,
      ),
    );
  });

  group('DiscoverStoriesCandidateAdapter', () {
    test('surfaces public matching stories via Discover*', () async {
      final hero = await _seedHero(heroes, name: 'Public Hero');
      final publicStory = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Public Courage',
        visibility: StoryVisibility.public,
        themes: [courage],
      );

      final candidates = await adapter.findRelevant(
        AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );

      expect(candidates.map((c) => c.storyId), [publicStory.id]);
      expect(candidates.single.themeOverlapCount, 1);
    });

    test('community stories remain eligible', () async {
      final hero = await _seedHero(
        heroes,
        name: 'Community Hero',
        visibility: HeroVisibility.community,
      );
      final communityStory = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Community Courage',
        visibility: StoryVisibility.community,
        themes: [courage],
      );

      final candidates = await adapter.findRelevant(
        AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );

      expect(candidates.map((c) => c.storyId), [communityStory.id]);
    });

    test('unlisted stories cannot be selected', () async {
      final hero = await _seedHero(heroes, name: 'Hero');
      await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Unlisted',
        visibility: StoryVisibility.unlisted,
        themes: [courage],
      );

      final candidates = await adapter.findRelevant(
        AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );

      expect(candidates, isEmpty);
    });

    test('private hero stories cannot surface even if story is public', () async {
      final privateHero = await _seedHero(
        heroes,
        name: 'Hidden',
        visibility: HeroVisibility.private,
      );
      await _seedPublishedStory(
        stories,
        hero: privateHero,
        title: 'Leak Candidate',
        visibility: StoryVisibility.public,
        themes: [courage],
      );

      final candidates = await adapter.findRelevant(
        AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );

      expect(candidates, isEmpty);
    });

    test('no themes returns empty candidates (patterns alone)', () async {
      final hero = await _seedHero(heroes, name: 'Hero');
      await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Courage',
        themes: [courage],
      );

      final candidates = await adapter.findRelevant(
        AdaptiveDiscoverySignals(behaviorPatterns: [_consistency()]),
      );

      expect(candidates, isEmpty);
    });

    test('patterns strengthen ranked candidates when themes match', () async {
      final hero = await _seedHero(heroes, name: 'Hero');
      await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Courage',
        themes: [courage],
      );

      final without = await adapter.findRelevant(
        AdaptiveDiscoverySignals(narrativeThemeIds: [courage]),
      );
      final withPatterns = await adapter.findRelevant(
        AdaptiveDiscoverySignals(
          narrativeThemeIds: [courage],
          behaviorPatterns: [_consistency(0.85)],
        ),
      );

      expect(without.single.patternBoost, 0.0);
      expect(withPatterns.single.patternBoost, 0.85);
    });
  });
}

Future<Hero> _seedHero(
  InMemoryHeroRepository heroes, {
  required String name,
  HeroVisibility visibility = HeroVisibility.public,
}) async {
  final hero = Hero.create(
    id: HeroId.generate(),
    profile: HeroProfile(
      displayName: name,
      biography: 'Lived experience.',
      experienceAreas: const ['Military'],
      languages: [LanguageCode('en')],
    ),
    visibility: visibility,
  );
  await heroes.save(hero);
  return hero;
}

Future<Story> _seedPublishedStory(
  InMemoryStoryRepository stories, {
  required Hero hero,
  required String title,
  StoryVisibility visibility = StoryVisibility.public,
  List<NarrativeThemeId> themes = const [],
}) async {
  final story = Story.create(
    id: StoryId.generate(),
    heroId: hero.id,
    title: StoryTitle(title),
    narrative: StoryNarrative('A published lived experience for $title.'),
    originalLanguage: LanguageCode('en'),
  );
  if (themes.isNotEmpty) {
    story.classify(StoryClassification(narrativeThemeIds: themes));
  }
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

  await stories.save(story);
  return story;
}

BehaviorPattern _consistency([double strength = 0.8]) {
  final evidence = [
    BehavioralEvidenceBuilder()
        .withType(BehavioralEvidenceType.discipline)
        .observedAt(DateTime(2026, 8, 1))
        .build(),
    BehavioralEvidenceBuilder()
        .withType(BehavioralEvidenceType.discipline)
        .observedAt(DateTime(2026, 8, 2))
        .build(),
  ];

  return BehaviorPattern(
    type: BehaviorPatternType.consistency,
    strength: Strength(strength),
    supportingEvidence: evidence,
    firstObservedAt: DateTime(2026, 8, 1),
    lastObservedAt: DateTime(2026, 8, 2),
  );
}
