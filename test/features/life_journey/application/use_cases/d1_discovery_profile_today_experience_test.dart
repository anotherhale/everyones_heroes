import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/ports/repository_discovery_profile_theme_source.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/discover_stories_candidate_adapter.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';
import 'package:everyonesheroes/features/life_journey/application/services/adaptive_experience_composer.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/discovery/discovery_profile_fixture.dart';

void main() {
  final courage = NarrativeThemeId('courage');

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

  Future<Journey> seedJourney() async {
    final journey = Journey.create(
      id: JourneyId.generate(),
      vision: JourneyVision('Become someone who shows up.'),
    );
    await journeyRepository.save(journey);
    currentJourneyContext.setCurrentJourney(journey.id);
    return journey;
  }

  test(
    'D.1/D.9: DiscoveryProfile-only match attributes Inspiration, not Reflection',
    () async {
      // Architectural contract (D.9): DiscoveryProfile-only theme match
      // ≠ recent Reflection. Rationale must identify Inspiration semantics
      // and must not claim the user recently reflected on the matched theme.
      await seedJourney();
      await discoveryProfileRepository.save(
        DiscoveryProfileFixture.create(
          userId: userId,
          narrativeThemeIds: [courage],
        ),
      );

      final hero = await _seedHero(heroes, name: 'Courage Hero');
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Facing Fear',
        themes: [courage],
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
    },
  );

  test(
    'D.1: without DiscoveryProfile themes, cold start stays reflection',
    () async {
      await seedJourney();

      final result = await useCase.execute();

      result.fold(
        onSuccess: (experience) {
          expect(experience.type, ExperienceType.reflection);
          expect(experience.id, 'default-reflection');
        },
        onFailure: fail,
      );
    },
  );
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
