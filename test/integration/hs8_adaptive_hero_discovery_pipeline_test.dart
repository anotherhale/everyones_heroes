import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';
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
import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';
import 'package:everyonesheroes/features/life_journey/application/services/adaptive_experience_composer.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_journey_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';

final class TestEventBus implements EventBus {
  final List<DomainEvent> publishedEvents = [];

  @override
  Future<void> publish(DomainEvent event) async {
    publishedEvents.add(event);
  }
}

void main() {
  late InMemoryJourneyRepository journeyRepository;
  late InMemoryReflectionRepository reflectionRepository;
  late CurrentJourneyContext currentJourneyContext;
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late CreateJourneyUseCase createJourneyUseCase;
  late GetTodayExperienceUseCase getTodayExperienceUseCase;

  final courage = NarrativeThemeId('courage');
  final perseverance = NarrativeThemeId('perseverance');

  setUp(() {
    journeyRepository = InMemoryJourneyRepository();
    reflectionRepository = InMemoryReflectionRepository();
    currentJourneyContext = DefaultCurrentJourneyContext();
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();

    final eventBus = TestEventBus();
    createJourneyUseCase = CreateJourneyUseCase(
      journeyRepository: journeyRepository,
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
    'HS.8 proof: understanding A → experience A; updated themes → experience B',
    () async {
      final journeyId = JourneyId.generate();
      final createResult = await createJourneyUseCase.execute(
        CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Become the person I want to be.'),
        ),
      );
      final journey = createResult.fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );
      currentJourneyContext.setCurrentJourney(journey.id);

      final hero = Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Ada',
          biography: 'Lived experience.',
          experienceAreas: const ['Leadership'],
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.public,
      );
      await heroes.save(hero);

      final storyA = await _seedStory(
        stories,
        hero: hero,
        title: 'Story A Courage',
        themes: [courage],
        at: DateTime.utc(2026, 1, 1),
      );
      final storyB = await _seedStory(
        stories,
        hero: hero,
        title: 'Story B Perseverance',
        themes: [perseverance],
        at: DateTime.utc(2026, 1, 2),
      );

      // Initial understanding: courage themes only.
      await _saveThemes(
        reflectionRepository,
        journeyId: journey.id,
        themes: [courage],
      );

      final experienceA = (await getTodayExperienceUseCase.execute()).fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(experienceA.type, ExperienceType.story);
      expect(
        (experienceA.target as StoryExperienceTarget).storyId,
        storyA.id,
      );

      // Updated understanding: perseverance themes.
      await _saveThemes(
        reflectionRepository,
        journeyId: journey.id,
        themes: [perseverance],
      );

      final experienceB = (await getTodayExperienceUseCase.execute()).fold(
        onSuccess: (value) => value,
        onFailure: (error) => throw StateError(error),
      );

      expect(experienceB.type, ExperienceType.story);
      // Union is courage+perseverance; perseverance is more recent → Story B.
      expect(
        (experienceB.target as StoryExperienceTarget).storyId,
        storyB.id,
      );
      expect(experienceB.id, isNot(experienceA.id));
    },
  );
}

Future<void> _saveThemes(
  InMemoryReflectionRepository repository, {
  required JourneyId journeyId,
  required List<NarrativeThemeId> themes,
}) async {
  final reflection = Reflection.create(
    id: ReflectionId.generate(),
    journeyId: journeyId,
  );
  reflection.addResponse(
    const JournalResponse(response: 'I reflected on growth.'),
  );
  reflection.submit();
  reflection.addNarrativeThemes(themes);
  await repository.save(reflection);
}

Future<Story> _seedStory(
  InMemoryStoryRepository stories, {
  required Hero hero,
  required String title,
  required List<NarrativeThemeId> themes,
  required DateTime at,
}) async {
  final story = Story.create(
    id: StoryId.generate(),
    heroId: hero.id,
    title: StoryTitle(title),
    narrative: StoryNarrative('Narrative for $title'),
    originalLanguage: LanguageCode('en'),
    createdAt: at,
  );
  story.classify(StoryClassification(narrativeThemeIds: themes));
  story.updateConsent(
    story.consent.grantProcessing(at).grantPublication(at),
  );
  story
    ..submit(at: at)
    ..markReadyForReview(at: at)
    ..approve(at: at)
    ..changeVisibility(StoryVisibility.public)
    ..publish(at: at);
  await stories.save(story);
  return story;
}
