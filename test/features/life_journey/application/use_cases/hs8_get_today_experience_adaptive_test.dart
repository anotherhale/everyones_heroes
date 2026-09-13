import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/discover_stories_candidate_adapter.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/discoverable_story_candidate_port.dart';
import 'package:everyonesheroes/features/life_journey/application/services/adaptive_experience_composer.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final courage = NarrativeThemeId('courage');
  final service = NarrativeThemeId('service');

  late InMemoryJourneyRepository journeyRepository;
  late InMemoryReflectionRepository reflectionRepository;
  late CurrentJourneyContext currentJourneyContext;
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late DefaultGetTodayExperienceUseCase useCase;

  setUp(() {
    journeyRepository = InMemoryJourneyRepository();
    reflectionRepository = InMemoryReflectionRepository();
    currentJourneyContext = DefaultCurrentJourneyContext();
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();

    const selection = DeterministicExperienceSelectionService();
    useCase = DefaultGetTodayExperienceUseCase(
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

  Future<Journey> seedJourney() async {
    final journey = Journey.create(
      id: JourneyId.generate(),
      vision: JourneyVision('Become someone who shows up.'),
    );
    await journeyRepository.save(journey);
    currentJourneyContext.setCurrentJourney(journey.id);
    return journey;
  }

  test('cold start without themes/patterns keeps reflection experience', () async {
    await seedJourney();

    final result = await useCase.execute();

    result.fold(
      onSuccess: (experience) {
        expect(experience.type, ExperienceType.reflection);
        expect(experience.id, 'default-reflection');
        expect(experience.target, isNull);
      },
      onFailure: fail,
    );
  });

  test('themes alone can produce adaptive story experience', () async {
    final journey = await seedJourney();
    await _saveReflectionWithThemes(
      reflectionRepository,
      journeyId: journey.id,
      themes: [courage],
    );

    final hero = await _seedHero(heroes, name: 'Hero');
    final story = await _seedPublishedStory(
      stories,
      hero: hero,
      title: 'Courage Story',
      themes: [courage],
    );

    final result = await useCase.execute();

    result.fold(
      onSuccess: (experience) {
        expect(experience.type, ExperienceType.story);
        expect(experience.target, StoryExperienceTarget(storyId: story.id));
        expect(
          experience.rationale,
          'This story connects with themes you\'ve recently reflected on.',
        );
      },
      onFailure: fail,
    );
  });

  test('updated understanding can change adaptive story selection', () async {
    final journey = await seedJourney();
    final hero = await _seedHero(heroes, name: 'Hero');
    final courageStory = await _seedPublishedStory(
      stories,
      hero: hero,
      title: 'Courage Story',
      themes: [courage],
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final serviceStory = await _seedPublishedStory(
      stories,
      hero: hero,
      title: 'Service Story',
      themes: [service],
      createdAt: DateTime.utc(2026, 1, 2),
    );

    await _saveReflectionWithThemes(
      reflectionRepository,
      journeyId: journey.id,
      themes: [courage],
    );

    final first = await useCase.execute();
    late String firstExperienceId;
    first.fold(
      onSuccess: (experience) {
        expect(experience.type, ExperienceType.story);
        expect(
          (experience.target as StoryExperienceTarget).storyId,
          courageStory.id,
        );
        firstExperienceId = experience.id;
      },
      onFailure: fail,
    );

    await _saveReflectionWithThemes(
      reflectionRepository,
      journeyId: journey.id,
      themes: [service],
    );

    final second = await useCase.execute();
    second.fold(
      onSuccess: (experience) {
        expect(experience.type, ExperienceType.story);
        expect(
          (experience.target as StoryExperienceTarget).storyId,
          serviceStory.id,
        );
        expect(experience.id, isNot(firstExperienceId));
      },
      onFailure: fail,
    );
  });

  test('empty candidate port falls back without breaking Today\'s Experience',
      () async {
    final journey = await seedJourney();
    await _saveReflectionWithThemes(
      reflectionRepository,
      journeyId: journey.id,
      themes: [courage],
    );

    final emptyPortUseCase = DefaultGetTodayExperienceUseCase(
      journeyRepository: journeyRepository,
      currentJourneyContext: currentJourneyContext,
      experienceSelectionService:
          const DeterministicExperienceSelectionService(),
      resolveAdaptiveDiscoverySignals:
          DefaultResolveAdaptiveDiscoverySignalsUseCase(
            reflectionRepository: reflectionRepository,
          ),
      storyCandidatePort: const EmptyDiscoverableStoryCandidatePort(),
    );

    final result = await emptyPortUseCase.execute();
    result.fold(
      onSuccess: (experience) {
        expect(experience.type, ExperienceType.reflection);
      },
      onFailure: fail,
    );
    expect(journey.id, isNotNull);
  });
}

Future<void> _saveReflectionWithThemes(
  InMemoryReflectionRepository repository, {
  required JourneyId journeyId,
  required List<NarrativeThemeId> themes,
}) async {
  final reflection = Reflection.create(
    id: ReflectionId.generate(),
    journeyId: journeyId,
  );
  reflection.addResponse(
    const JournalResponse(response: 'I reflected on what matters.'),
  );
  reflection.submit();
  reflection.addNarrativeThemes(themes);
  await repository.save(reflection);
}

Future<Hero> _seedHero(
  InMemoryHeroRepository heroes, {
  required String name,
}) async {
  final hero = Hero.create(
    id: HeroId.generate(),
    profile: HeroProfile(
      displayName: name,
      biography: 'Lived experience.',
      experienceAreas: const ['Service'],
      languages: [LanguageCode('en')],
    ),
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
