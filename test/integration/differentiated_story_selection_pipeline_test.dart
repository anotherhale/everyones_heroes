import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/discover_stories_candidate_adapter.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/analyze_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/fake/services/fake_insight_extraction_service.dart';
import 'package:everyonesheroes/features/life_journey/application/services/adaptive_experience_composer.dart';
import 'package:everyonesheroes/features/life_journey/application/services/behavioral_evidence_analysis_orchestrator.dart';
import 'package:everyonesheroes/features/life_journey/application/services/default_behavioral_evidence_analyzer_registry.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/analyze_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/life_journey/application/services/fake_behaviorial_evidence_analyzer.dart';

/// Slice B DoD: Reflection → analysis (production theme resolver) → Today
/// selects a different adaptive-story-* Story identity.
///
/// Slice C DoD: same pipeline with natural-language description/alias phrases
/// (no literal catalog theme names required).
void main() {
  late InMemoryJourneyRepository journeyRepository;
  late InMemoryReflectionRepository reflectionRepository;
  late CurrentJourneyContext currentJourneyContext;
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late AnalyzeReflectionUseCase analyzeReflectionUseCase;
  late DefaultGetTodayExperienceUseCase getTodayExperienceUseCase;

  setUp(() {
    journeyRepository = InMemoryJourneyRepository();
    reflectionRepository = InMemoryReflectionRepository();
    currentJourneyContext = DefaultCurrentJourneyContext();
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();

    final eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );

    analyzeReflectionUseCase = AnalyzeReflectionUseCase(
      reflectionRepository: reflectionRepository,
      insightExtractionService: const FakeInsightExtractionService(),
      behavioralEvidenceAnalysisOrchestrator:
          BehavioralEvidenceAnalysisOrchestrator(
        registry: DefaultBehavioralEvidenceAnalyzerRegistry([
          const FakeBehavioralEvidenceAnalyzer(),
        ]),
      ),
      // Production catalog-aligned resolver — not manual theme planting.
      narrativeThemeResolver: const CatalogAlignedNarrativeThemeResolver(),
      eventBus: eventBus,
    );

    const selection = DeterministicExperienceSelectionService();
    getTodayExperienceUseCase = DefaultGetTodayExperienceUseCase(
      journeyRepository: journeyRepository,
      currentJourneyContext: currentJourneyContext,
      experienceSelectionService: selection,
      resolveAdaptiveDiscoverySignals:
          DefaultResolveAdaptiveDiscoverySignalsUseCase(
        reflectionRepository: reflectionRepository,
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

  test(
    'Reflection analysis differentiates adaptive-story-* Story identity',
    () async {
      final journey = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become someone who shows up.'),
      );
      await journeyRepository.save(journey);
      currentJourneyContext.setCurrentJourney(journey.id);

      final hero = Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Ada',
          biography: 'Lived experience.',
          experienceAreas: const ['Service'],
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.public,
      );
      await heroes.save(hero);

      final storyA = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Story A Courage',
        themes: [NarrativeThemeReferenceIds.courage],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final storyB = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Story B Service',
        themes: [NarrativeThemeReferenceIds.service],
        createdAt: DateTime.utc(2026, 1, 2),
      );

      // Initial understanding: content that resolves to courage → Story A.
      await _submitAndAnalyze(
        analyzeReflectionUseCase,
        reflectionRepository,
        journeyId: journey.id,
        journalText: 'Today I found courage when I spoke up.',
      );

      final first = (await getTodayExperienceUseCase.execute()).fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(first.type, ExperienceType.story);
      expect(first.id, 'adaptive-story-${storyA.id.value}');
      expect(
        (first.target as StoryExperienceTarget).storyId,
        storyA.id,
      );

      // Updated understanding: content that resolves to service → Story B.
      await _submitAndAnalyze(
        analyzeReflectionUseCase,
        reflectionRepository,
        journeyId: journey.id,
        journalText: 'I want to grow through service to others.',
      );

      final second = (await getTodayExperienceUseCase.execute()).fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(second.type, ExperienceType.story);
      expect(second.id, 'adaptive-story-${storyB.id.value}');
      expect(
        (second.target as StoryExperienceTarget).storyId,
        storyB.id,
      );
      expect(second.id, isNot(first.id));
    },
  );

  test(
    'natural-language description phrases differentiate Story identity',
    () async {
      final journey = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become someone who shows up.'),
      );
      await journeyRepository.save(journey);
      currentJourneyContext.setCurrentJourney(journey.id);

      final hero = Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Ada',
          biography: 'Lived experience.',
          experienceAreas: const ['Service'],
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.public,
      );
      await heroes.save(hero);

      final storyA = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Story A Courage',
        themes: [NarrativeThemeReferenceIds.courage],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final storyB = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Story B Service',
        themes: [NarrativeThemeReferenceIds.service],
        createdAt: DateTime.utc(2026, 1, 2),
      );

      // Natural language uses catalog description for Courage
      // ("Acting despite fear.") — not the theme name.
      await _submitAndAnalyze(
        analyzeReflectionUseCase,
        reflectionRepository,
        journeyId: journey.id,
        journalText:
            'Lately I notice myself acting despite fear in small moments.',
        expectedTheme: NarrativeThemeReferenceIds.courage,
      );

      final first = (await getTodayExperienceUseCase.execute()).fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(first.type, ExperienceType.story);
      expect(first.id, 'adaptive-story-${storyA.id.value}');
      expect(
        (first.target as StoryExperienceTarget).storyId,
        storyA.id,
      );

      // Natural language uses catalog description for Service
      // ("Helping others through lived experience.") — not the theme name.
      await _submitAndAnalyze(
        analyzeReflectionUseCase,
        reflectionRepository,
        journeyId: journey.id,
        journalText:
            'I keep returning to helping others through lived experience '
            'as my real direction.',
        expectedTheme: NarrativeThemeReferenceIds.service,
      );

      final second = (await getTodayExperienceUseCase.execute()).fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(second.type, ExperienceType.story);
      expect(second.id, 'adaptive-story-${storyB.id.value}');
      expect(
        (second.target as StoryExperienceTarget).storyId,
        storyB.id,
      );
      expect(second.id, isNot(first.id));
      expect(
        (second.target as StoryExperienceTarget).storyId,
        isNot((first.target as StoryExperienceTarget).storyId),
      );
    },
  );

  test(
    'theme-recency ranking selects older Story matching recent theme',
    () async {
      final journey = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become someone who shows up.'),
      );
      await journeyRepository.save(journey);
      currentJourneyContext.setCurrentJourney(journey.id);

      final hero = Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Ada',
          biography: 'Lived experience.',
          experienceAreas: const ['Service'],
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.public,
      );
      await heroes.save(hero);

      // Intentionally adverse: courage Story is newer than service Story.
      final courageStory = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Story A Courage (newer updatedAt)',
        themes: [NarrativeThemeReferenceIds.courage],
        createdAt: DateTime.utc(2026, 3, 1),
      );
      final serviceStory = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Story B Service (older updatedAt)',
        themes: [NarrativeThemeReferenceIds.service],
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(
        courageStory.updatedAt.isAfter(serviceStory.updatedAt),
        isTrue,
        reason: 'Fixture must make Story timestamp unable to explain the win',
      );
      expect(courageStory.id, isNot(serviceStory.id));

      await _submitAndAnalyze(
        analyzeReflectionUseCase,
        reflectionRepository,
        journeyId: journey.id,
        journalText: 'Today I found courage when I spoke up.',
        expectedTheme: NarrativeThemeReferenceIds.courage,
      );

      final afterCourage = (await getTodayExperienceUseCase.execute()).fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );
      expect(afterCourage.type, ExperienceType.story);
      expect(
        (afterCourage.target as StoryExperienceTarget).storyId,
        courageStory.id,
      );

      await _submitAndAnalyze(
        analyzeReflectionUseCase,
        reflectionRepository,
        journeyId: journey.id,
        journalText: 'I want to grow through service to others.',
        expectedTheme: NarrativeThemeReferenceIds.service,
      );

      final afterService = (await getTodayExperienceUseCase.execute()).fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(afterService.type, ExperienceType.story);
      expect(
        (afterService.target as StoryExperienceTarget).storyId,
        serviceStory.id,
        reason:
            'Recent service theme must beat newer courage Story updatedAt',
      );
      expect(
        (afterService.target as StoryExperienceTarget).storyId,
        isNot((afterCourage.target as StoryExperienceTarget).storyId),
      );
      expect(afterService.id, 'adaptive-story-${serviceStory.id.value}');
      expect(afterService.id, isNot(afterCourage.id));
    },
  );
}

Future<void> _submitAndAnalyze(
  AnalyzeReflectionUseCase analyze,
  InMemoryReflectionRepository repository, {
  required JourneyId journeyId,
  required String journalText,
  NarrativeThemeId? expectedTheme,
}) async {
  final reflection = Reflection.create(
    id: ReflectionId.generate(),
    journeyId: journeyId,
  );
  reflection.addResponse(JournalResponse(response: journalText));
  reflection.submit();
  reflection.pullDomainEvents();
  await repository.save(reflection);

  final result = await analyze.execute(
    AnalyzeReflectionRequest(reflectionId: reflection.id),
  );
  result.fold(
    onSuccess: (_) {},
    onFailure: (error) => throw StateError(error),
  );

  final analyzed = await repository.findById(reflection.id);
  expect(analyzed, isNotNull);
  expect(analyzed!.narrativeThemes, isNotEmpty);
  if (expectedTheme != null) {
    expect(analyzed.narrativeThemes, contains(expectedTheme));
  }
}

Future<Story> _seedPublishedStory(
  InMemoryStoryRepository stories, {
  required Hero hero,
  required String title,
  required List<NarrativeThemeId> themes,
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
  story.classify(StoryClassification(narrativeThemeIds: themes));
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
