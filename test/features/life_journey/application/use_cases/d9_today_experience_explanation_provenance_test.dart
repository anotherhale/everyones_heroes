import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/ports/repository_discovery_profile_theme_source.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_discovery_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/deterministic_story_relevance_ranker.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/discover_stories_candidate_adapter.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/discoverable_story_candidate.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';
import 'package:everyonesheroes/features/life_journey/application/models/narrative_theme_match_source.dart';
import 'package:everyonesheroes/features/life_journey/application/services/adaptive_experience_composer.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/services/narrative_theme_match_provenance.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/discovery/discovery_profile_fixture.dart';
import '../../builders/behavioral_evidence_builder.dart';

/// D.9 — Today Experience Explanation Provenance.
///
/// Ranking must remain identical; only rationale attribution changes.
void main() {
  final perseverance = NarrativeThemeId('perseverance');
  final courage = NarrativeThemeId('courage');

  group('NarrativeThemeMatchProvenance', () {
    test('inspiration-only matched theme → inspiration', () {
      final source = NarrativeThemeMatchProvenance.resolveFromThemeIds(
        matchedThemeIds: [perseverance],
        inspirationThemeIds: [perseverance],
        reflectionThemeValues: const [],
      );
      expect(source, NarrativeThemeMatchSource.inspiration);
    });

    test('reflection-only matched theme → reflection', () {
      final source = NarrativeThemeMatchProvenance.resolveFromThemeIds(
        matchedThemeIds: [perseverance],
        inspirationThemeIds: const [],
        reflectionThemeValues: ['perseverance'],
      );
      expect(source, NarrativeThemeMatchSource.reflection);
    });

    test('same matched theme in both sources → mixed', () {
      final source = NarrativeThemeMatchProvenance.resolveFromThemeIds(
        matchedThemeIds: [perseverance],
        inspirationThemeIds: [perseverance],
        reflectionThemeValues: ['perseverance'],
      );
      expect(source, NarrativeThemeMatchSource.mixed);
    });

    test('different matched themes from different sources → mixed', () {
      final source = NarrativeThemeMatchProvenance.resolveFromThemeIds(
        matchedThemeIds: [perseverance, courage],
        inspirationThemeIds: [perseverance],
        reflectionThemeValues: ['courage'],
      );
      expect(source, NarrativeThemeMatchSource.mixed);
    });

    test('matched theme in neither source → unknown', () {
      final source = NarrativeThemeMatchProvenance.resolveFromThemeIds(
        matchedThemeIds: [perseverance],
        inspirationThemeIds: [courage],
        reflectionThemeValues: const [],
      );
      expect(source, NarrativeThemeMatchSource.unknown);
    });
  });

  group('AdaptiveExperienceComposer D.9 rationale matrix', () {
    const composer = AdaptiveExperienceComposer(
      reflectionSelectionService: DeterministicExperienceSelectionService(),
    );

    DiscoverableStoryCandidate candidate({
      required List<NarrativeThemeId> matched,
    }) {
      return DiscoverableStoryCandidate(
        storyId: StoryId('story-1'),
        heroId: HeroId('hero-1'),
        title: 'Selected Story',
        matchedThemeIds: matched,
        themeOverlapCount: matched.length,
        patternBoost: 0.0,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    }

    test('Case A: Inspiration-only — no reflection claim', () {
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [perseverance],
        inspirationThemeIds: [perseverance],
      );
      final top = candidate(matched: [perseverance]);

      final experience = composer.compose(
        journey: Journey(
          id: JourneyId('j1'),
          vision: JourneyVision('Grow.'),
        ),
        signals: signals,
        candidates: [top],
      );

      expect(experience.target, StoryExperienceTarget(storyId: top.storyId));
      expect(
        experience.rationale,
        'This story connects with themes from your inspirations.',
      );
      expect(experience.rationale!.toLowerCase(), isNot(contains('reflected')));
    });

    test('Case B: Reflection-only — retains reflection semantics', () {
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [perseverance],
        themeLastExpressedAt: {'perseverance': DateTime.utc(2026, 3, 1)},
      );
      final top = candidate(matched: [perseverance]);

      final experience = composer.compose(
        journey: Journey(
          id: JourneyId('j1'),
          vision: JourneyVision('Grow.'),
        ),
        signals: signals,
        candidates: [top],
      );

      expect(experience.target, StoryExperienceTarget(storyId: top.storyId));
      expect(
        experience.rationale,
        'This story connects with themes you\'ve recently reflected on.',
      );
    });

    test('Case C: Mixed same-theme — not exclusively Reflection', () {
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [perseverance],
        inspirationThemeIds: [perseverance],
        themeLastExpressedAt: {'perseverance': DateTime.utc(2026, 3, 1)},
      );
      final top = candidate(matched: [perseverance]);

      final experience = composer.compose(
        journey: Journey(
          id: JourneyId('j1'),
          vision: JourneyVision('Grow.'),
        ),
        signals: signals,
        candidates: [top],
      );

      expect(experience.target, StoryExperienceTarget(storyId: top.storyId));
      expect(
        experience.rationale,
        'This story connects with themes from your inspirations and reflections.',
      );
      expect(
        experience.rationale,
        isNot(
          equals(
            'This story connects with themes you\'ve recently reflected on.',
          ),
        ),
      );
    });

    test('Case D: Mixed different themes — both sources', () {
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [perseverance, courage],
        inspirationThemeIds: [perseverance],
        themeLastExpressedAt: {'courage': DateTime.utc(2026, 3, 1)},
      );
      final top = candidate(matched: [perseverance, courage]);

      final experience = composer.compose(
        journey: Journey(
          id: JourneyId('j1'),
          vision: JourneyVision('Grow.'),
        ),
        signals: signals,
        candidates: [top],
      );

      expect(experience.target, StoryExperienceTarget(storyId: top.storyId));
      expect(
        experience.rationale,
        'This story connects with themes from your inspirations and reflections.',
      );
    });

    test('Case E: Pattern + Inspiration — not mislabeled as Reflection', () {
      final patterns = [_consistencyPattern()];
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [perseverance],
        inspirationThemeIds: [perseverance],
        behaviorPatterns: patterns,
      );
      final top = candidate(matched: [perseverance]);

      final experience = composer.compose(
        journey: Journey(
          id: JourneyId('j1'),
          vision: JourneyVision('Grow.'),
          behaviorPatterns: patterns,
        ),
        signals: signals,
        candidates: [top],
      );

      expect(experience.target, StoryExperienceTarget(storyId: top.storyId));
      expect(experience.rationale, contains('themes from your inspirations'));
      expect(experience.rationale, contains('patterns of consistency'));
      expect(experience.rationale!.toLowerCase(), isNot(contains('reflected')));
    });

    test('Case F: Unknown — neutral, no invented provenance', () {
      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: [perseverance],
      );
      final top = candidate(matched: [perseverance]);

      final experience = composer.compose(
        journey: Journey(
          id: JourneyId('j1'),
          vision: JourneyVision('Grow.'),
        ),
        signals: signals,
        candidates: [top],
      );

      expect(
        experience.rationale,
        'This story connects with themes relevant to your journey.',
      );
      expect(experience.rationale!.toLowerCase(), isNot(contains('reflected')));
      expect(
        experience.rationale!.toLowerCase(),
        isNot(contains('inspiration')),
      );
    });
  });

  group('D.9 ranking regression', () {
    const ranker = DeterministicStoryRelevanceRanker();

    test(
      'inspirationThemeIds does not change DeterministicStoryRelevanceRanker order',
      () {
        final summaries = [
          _summary(
            id: 'story-a',
            themes: [perseverance],
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          _summary(
            id: 'story-b',
            themes: [perseverance, courage],
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
          _summary(
            id: 'story-c',
            themes: [courage],
            updatedAt: DateTime.utc(2026, 1, 3),
          ),
        ];

        final withoutProvenance = AdaptiveDiscoverySignals(
          narrativeThemeIds: [perseverance, courage],
          themeLastExpressedAt: {
            'courage': DateTime.utc(2026, 2, 1),
          },
        );
        final withProvenance = AdaptiveDiscoverySignals(
          narrativeThemeIds: [perseverance, courage],
          themeLastExpressedAt: {
            'courage': DateTime.utc(2026, 2, 1),
          },
          inspirationThemeIds: [perseverance],
        );

        final before = ranker.rank(
          summaries: summaries,
          signals: withoutProvenance,
        );
        final after = ranker.rank(
          summaries: summaries,
          signals: withProvenance,
        );

        expect(
          after.map((c) => c.storyId.value).toList(),
          before.map((c) => c.storyId.value).toList(),
        );
        expect(
          after.map((c) => c.themeOverlapCount).toList(),
          before.map((c) => c.themeOverlapCount).toList(),
        );
        expect(
          after.map((c) => c.patternBoost).toList(),
          before.map((c) => c.patternBoost).toList(),
        );
      },
    );
  });

  group('D.9 end-to-end Today Experience provenance', () {
    late InMemoryJourneyRepository journeyRepository;
    late InMemoryReflectionRepository reflectionRepository;
    late InMemoryDiscoveryProfileRepository discoveryProfileRepository;
    late CurrentJourneyContext currentJourneyContext;
    late InMemoryHeroRepository heroes;
    late InMemoryStoryRepository stories;
    late DefaultGetTodayExperienceUseCase useCase;
    late UserId userId;

    setUp(() {
      journeyRepository = InMemoryJourneyRepository();
      reflectionRepository = InMemoryReflectionRepository();
      discoveryProfileRepository = InMemoryDiscoveryProfileRepository();
      currentJourneyContext = DefaultCurrentJourneyContext();
      heroes = InMemoryHeroRepository();
      stories = InMemoryStoryRepository();
      userId = UserId('dev-user');

      const selection = DeterministicExperienceSelectionService();
      useCase = DefaultGetTodayExperienceUseCase(
        journeyRepository: journeyRepository,
        currentJourneyContext: currentJourneyContext,
        experienceSelectionService: selection,
        resolveAdaptiveDiscoverySignals:
            DefaultResolveAdaptiveDiscoverySignalsUseCase(
              reflectionRepository: reflectionRepository,
              discoveryProfileThemeSource: RepositoryDiscoveryProfileThemeSource(
                discoveryProfileRepository: discoveryProfileRepository,
                currentUserId: userId,
              ),
            ),
        storyCandidatePort: DiscoverStoriesCandidateAdapter(
          discoverStoriesUseCase: DiscoverStoriesUseCase(
            storySearchPort: InMemoryStorySearchAdapter(stories),
            storyRepository: stories,
            heroRepository: heroes,
          ),
        ),
        composer: const AdaptiveExperienceComposer(
          reflectionSelectionService: selection,
        ),
      );
    });

    Future<Journey> seedJourney({List<BehaviorPattern> patterns = const []}) async {
      final journey = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become someone who shows up.'),
      );
      if (patterns.isNotEmpty) {
        journey.updateBehaviorPatterns(patterns);
      }
      await journeyRepository.save(journey);
      currentJourneyContext.setCurrentJourney(journey.id);
      return journey;
    }

    test('Inspiration-only Today Story — selected id unchanged, Inspiration copy',
        () async {
      await seedJourney();
      await discoveryProfileRepository.save(
        DiscoveryProfileFixture.create(
          userId: userId,
          narrativeThemeIds: [perseverance],
        ),
      );
      final hero = await _seedHero(heroes);
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Perseverance Story',
        themes: [perseverance],
      );

      final result = await useCase.execute();
      result.fold(
        onSuccess: (experience) {
          expect(experience.type, ExperienceType.story);
          expect(experience.target, StoryExperienceTarget(storyId: story.id));
          expect(
            experience.rationale,
            'This story connects with themes from your inspirations.',
          );
          expect(
            experience.rationale!.toLowerCase(),
            isNot(contains('reflected')),
          );
        },
        onFailure: fail,
      );
    });

    test('Reflection-only Today Story — Reflection copy retained', () async {
      final journey = await seedJourney();
      await _saveReflection(
        reflectionRepository,
        journeyId: journey.id,
        themes: [perseverance],
      );
      final hero = await _seedHero(heroes);
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Perseverance Story',
        themes: [perseverance],
      );

      final result = await useCase.execute();
      result.fold(
        onSuccess: (experience) {
          expect(experience.target, StoryExperienceTarget(storyId: story.id));
          expect(
            experience.rationale,
            'This story connects with themes you\'ve recently reflected on.',
          );
        },
        onFailure: fail,
      );
    });

    test('Mixed same-theme — not exclusively Reflection; story unchanged',
        () async {
      final journey = await seedJourney();
      await discoveryProfileRepository.save(
        DiscoveryProfileFixture.create(
          userId: userId,
          narrativeThemeIds: [perseverance],
        ),
      );
      await _saveReflection(
        reflectionRepository,
        journeyId: journey.id,
        themes: [perseverance],
      );
      final hero = await _seedHero(heroes);
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Perseverance Story',
        themes: [perseverance],
      );

      final result = await useCase.execute();
      result.fold(
        onSuccess: (experience) {
          expect(experience.target, StoryExperienceTarget(storyId: story.id));
          expect(
            experience.rationale,
            'This story connects with themes from your inspirations and reflections.',
          );
        },
        onFailure: fail,
      );
    });

    test('Mixed different themes — both sources; story unchanged', () async {
      final journey = await seedJourney();
      await discoveryProfileRepository.save(
        DiscoveryProfileFixture.create(
          userId: userId,
          narrativeThemeIds: [perseverance],
        ),
      );
      await _saveReflection(
        reflectionRepository,
        journeyId: journey.id,
        themes: [courage],
      );
      final hero = await _seedHero(heroes);
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Both Themes Story',
        themes: [perseverance, courage],
      );

      final result = await useCase.execute();
      result.fold(
        onSuccess: (experience) {
          expect(experience.target, StoryExperienceTarget(storyId: story.id));
          expect(
            experience.rationale,
            'This story connects with themes from your inspirations and reflections.',
          );
        },
        onFailure: fail,
      );
    });

    test('Pattern + Inspiration — pattern rationale preserved without Reflection claim',
        () async {
      final patterns = [_consistencyPattern()];
      await seedJourney(patterns: patterns);
      await discoveryProfileRepository.save(
        DiscoveryProfileFixture.create(
          userId: userId,
          narrativeThemeIds: [perseverance],
        ),
      );
      final hero = await _seedHero(heroes);
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Perseverance Story',
        themes: [perseverance],
      );

      final result = await useCase.execute();
      result.fold(
        onSuccess: (experience) {
          expect(experience.target, StoryExperienceTarget(storyId: story.id));
          expect(experience.rationale, contains('themes from your inspirations'));
          expect(experience.rationale, contains('patterns of consistency'));
          expect(
            experience.rationale!.toLowerCase(),
            isNot(contains('reflected')),
          );
        },
        onFailure: fail,
      );
    });

    test(
      'ranking: Inspiration vs Reflection provenance does not change selected Story',
      () async {
        final hero = await _seedHero(heroes);
        final highOverlap = await _seedPublishedStory(
          stories,
          hero: hero,
          title: 'Both',
          themes: [perseverance, courage],
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final lowOverlap = await _seedPublishedStory(
          stories,
          hero: hero,
          title: 'One',
          themes: [perseverance],
          createdAt: DateTime.utc(2026, 1, 2),
        );

        final profileId = DiscoveryProfileId('d9-ranking-profile');

        // Inspiration-only: same theme union as Reflection-only for ranking.
        await discoveryProfileRepository.save(
          DiscoveryProfileFixture.create(
            id: profileId,
            userId: userId,
            narrativeThemeIds: [perseverance, courage],
          ),
        );
        final journeyA = await seedJourney();
        final inspirationOnly = await useCase.execute();

        // Clear profile themes (same profile id); use reflections with same set.
        await discoveryProfileRepository.save(
          DiscoveryProfileFixture.create(
            id: profileId,
            userId: userId,
            narrativeThemeIds: const [],
          ),
        );
        await _saveReflection(
          reflectionRepository,
          journeyId: journeyA.id,
          themes: [perseverance, courage],
        );
        final reflectionOnly = await useCase.execute();

        StoryId? inspirationStoryId;
        StoryId? reflectionStoryId;
        inspirationOnly.fold(
          onSuccess: (e) {
            inspirationStoryId = (e.target as StoryExperienceTarget).storyId;
          },
          onFailure: fail,
        );
        reflectionOnly.fold(
          onSuccess: (e) {
            reflectionStoryId = (e.target as StoryExperienceTarget).storyId;
          },
          onFailure: fail,
        );

        expect(inspirationStoryId, highOverlap.id);
        expect(reflectionStoryId, highOverlap.id);
        expect(inspirationStoryId, reflectionStoryId);
        expect(inspirationStoryId, isNot(lowOverlap.id));
      },
    );
  });
}

BehaviorPattern _consistencyPattern() {
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
    strength: const Strength(0.8),
    supportingEvidence: evidence,
    firstObservedAt: DateTime(2026, 8, 1),
    lastObservedAt: DateTime(2026, 8, 2),
  );
}

StoryDiscoverySummary _summary({
  required String id,
  required List<NarrativeThemeId> themes,
  required DateTime updatedAt,
}) {
  return StoryDiscoverySummary(
    storyId: StoryId(id),
    heroId: HeroId('hero-$id'),
    title: id,
    originalLanguage: LanguageCode('en'),
    availableLanguages: [LanguageCode('en')],
    subjects: const [],
    challenges: const [],
    narrativeThemeIds: themes,
    outcomes: const [],
    emotionalCharacters: const [],
    visibility: StoryVisibility.public,
    spiritualityCategory: SpiritualityCategory.nonSpiritual,
    profanity: SuitabilityLevel.none,
    violence: SuitabilityLevel.none,
    sexualContent: SuitabilityLevel.none,
    substanceUse: SuitabilityLevel.none,
    disturbingContent: SuitabilityLevel.none,
    authoritativeRepresentations: const [],
    matchReasons: const [],
    updatedAt: updatedAt,
    createdAt: updatedAt,
  );
}

Future<Hero> _seedHero(InMemoryHeroRepository heroes) async {
  final hero = Hero.create(
    id: HeroId.generate(),
    profile: HeroProfile(
      displayName: 'Hero',
      biography: 'Lived experience.',
      experienceAreas: const ['Service'],
      languages: [LanguageCode('en')],
    ),
    visibility: HeroVisibility.public,
  );
  await heroes.save(hero);
  return hero;
}

Future<Story> _seedPublishedStory(
  InMemoryStoryRepository stories, {
  required Hero hero,
  required String title,
  List<NarrativeThemeId> themes = const [],
  DateTime? createdAt,
}) async {
  final story = Story.create(
    id: StoryId.generate(),
    heroId: hero.id,
    title: StoryTitle(title),
    narrative: StoryNarrative('A published lived experience for $title.'),
    originalLanguage: LanguageCode('en'),
    createdAt: createdAt,
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
    ..submit(at: createdAt)
    ..markReadyForReview(at: createdAt)
    ..approve(at: createdAt)
    ..changeVisibility(StoryVisibility.public)
    ..publish(at: createdAt);
  await stories.save(story);
  return story;
}

Future<void> _saveReflection(
  InMemoryReflectionRepository repository, {
  required JourneyId journeyId,
  required List<NarrativeThemeId> themes,
}) async {
  final at = DateTime.utc(2026, 3, 1);
  final reflection = Reflection(
    id: ReflectionId.generate(),
    journeyId: journeyId,
    createdAt: at,
    submittedAt: at,
    responses: const [JournalResponse(response: 'I showed up today.')],
    narrativeThemes: themes,
  );
  await repository.save(reflection);
}
