import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/ports/repository_discovery_profile_theme_source.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/remove_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/select_influences_use_case.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/services/in_memory_influence_theme_resolver.dart';
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

/// D.5 product loop:
/// Remove Influence → re-resolve Themes → AdaptiveDiscoverySignals →
/// Today's Experience may lose a theme-based Story match.
void main() {
  late InMemoryJourneyRepository journeyRepository;
  late InMemoryReflectionRepository reflectionRepository;
  late InMemoryDiscoveryProfileRepository discoveryProfileRepository;
  late InMemoryInfluenceRepository influenceRepository;
  late CurrentJourneyContext currentJourneyContext;
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late DefaultGetTodayExperienceUseCase todayExperience;
  late SelectInfluencesUseCase selectInfluences;
  late RemoveInfluenceUseCase removeInfluence;
  late DefaultResolveAdaptiveDiscoverySignalsUseCase resolveSignals;
  late UserId userId;

  setUp(() {
    journeyRepository = InMemoryJourneyRepository();
    reflectionRepository = InMemoryReflectionRepository();
    discoveryProfileRepository = InMemoryDiscoveryProfileRepository();
    influenceRepository = InMemoryInfluenceRepository.withReferenceCatalog();
    currentJourneyContext = DefaultCurrentJourneyContext();
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    userId = UserId('dev-user');

    final themeSource = RepositoryDiscoveryProfileThemeSource(
      discoveryProfileRepository: discoveryProfileRepository,
      currentUserId: userId,
    );
    resolveSignals = DefaultResolveAdaptiveDiscoverySignalsUseCase(
      reflectionRepository: reflectionRepository,
      discoveryProfileThemeSource: themeSource,
    );

    const selection = DeterministicExperienceSelectionService();
    todayExperience = DefaultGetTodayExperienceUseCase(
      journeyRepository: journeyRepository,
      currentJourneyContext: currentJourneyContext,
      experienceSelectionService: selection,
      resolveAdaptiveDiscoverySignals: resolveSignals,
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

    final ensure = EnsureCurrentDiscoveryProfileUseCase(
      repository: discoveryProfileRepository,
      currentUserId: userId,
    );
    final resolve = ResolveNarrativeThemesUseCase(
      repository: discoveryProfileRepository,
      resolver: InMemoryInfluenceThemeResolver(
        influenceRepository: influenceRepository,
      ),
    );
    selectInfluences = SelectInfluencesUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      addInfluence: AddInfluenceUseCase(
        repository: discoveryProfileRepository,
      ),
      resolveNarrativeThemes: resolve,
      influenceRepository: influenceRepository,
    );
    removeInfluence = RemoveInfluenceUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      repository: discoveryProfileRepository,
      resolveNarrativeThemes: resolve,
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
    'D.5: removing an Influence can remove a Story theme-based adaptive match',
    () async {
      final journey = await seedJourney();

      // Story classified with perseverance — Rocky exclusive vs Fred Rogers.
      final hero = await _seedHero(heroes, name: 'Perseverance Hero');
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Keep Going',
        themes: [NarrativeThemeReferenceIds.perseverance],
      );

      await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
        InfluenceReferenceIds.fredRogers,
      ]);

      final signalsBefore = await resolveSignals.execute(journey);
      expect(
        signalsBefore.narrativeThemeIds,
        contains(NarrativeThemeReferenceIds.perseverance),
      );
      expect(
        signalsBefore.narrativeThemeIds,
        contains(NarrativeThemeReferenceIds.love),
      );

      final before = await todayExperience.execute();
      before.fold(
        onSuccess: (experience) {
          expect(experience.type, ExperienceType.story);
          expect(experience.target, StoryExperienceTarget(storyId: story.id));
        },
        onFailure: fail,
      );

      // Remove Rocky → perseverance gone; Fred Rogers themes remain.
      final profile = await removeInfluence.execute(
        InfluenceReferenceIds.rockyBalboa,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.perseverance),
        isFalse,
      );
      expect(
        profile.containsTheme(NarrativeThemeReferenceIds.love),
        isTrue,
      );

      final signalsAfter = await resolveSignals.execute(journey);
      expect(
        signalsAfter.narrativeThemeIds,
        isNot(contains(NarrativeThemeReferenceIds.perseverance)),
      );
      expect(
        signalsAfter.narrativeThemeIds,
        contains(NarrativeThemeReferenceIds.love),
      );

      final after = await todayExperience.execute();
      after.fold(
        onSuccess: (experience) {
          // Perseverance Story is no longer theme-eligible; remaining
          // Influences still shape signals but this Story should not match.
          expect(
            experience.target,
            isNot(StoryExperienceTarget(storyId: story.id)),
          );
        },
        onFailure: fail,
      );
    },
  );

  test(
    'D.5: remaining Influences continue to influence Today\'s Experience',
    () async {
      await seedJourney();

      final hero = await _seedHero(heroes, name: 'Love Hero');
      final loveStory = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Neighborly Care',
        themes: [NarrativeThemeReferenceIds.love],
      );

      await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
        InfluenceReferenceIds.fredRogers,
      ]);

      await removeInfluence.execute(InfluenceReferenceIds.rockyBalboa);

      final result = await todayExperience.execute();
      result.fold(
        onSuccess: (experience) {
          expect(experience.type, ExperienceType.story);
          expect(
            experience.target,
            StoryExperienceTarget(storyId: loveStory.id),
          );
        },
        onFailure: fail,
      );
    },
  );

  test(
    'D.5: Influence removal does not create BehavioralEvidence or patterns',
    () async {
      final journey = await seedJourney();

      await selectInfluences.execute([
        InfluenceReferenceIds.rockyBalboa,
        InfluenceReferenceIds.aragorn,
      ]);
      await removeInfluence.execute(InfluenceReferenceIds.rockyBalboa);

      expect(journey.behaviorPatterns, isEmpty);

      final signals = await resolveSignals.execute(journey);
      expect(signals.behaviorPatterns, isEmpty);
      expect(signals.narrativeThemeIds, isNotEmpty);
    },
  );

  test(
    'D.5: existing Reflection themes still contribute to AdaptiveDiscoverySignals',
    () async {
      final journey = await seedJourney();

      final reflection = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: journey.id,
      );
      reflection.addResponse(
        const JournalResponse(response: 'I showed up today.'),
      );
      reflection.submit();
      reflection.addNarrativeThemes([NarrativeThemeReferenceIds.leadership]);
      await reflectionRepository.save(reflection);

      await selectInfluences.execute([InfluenceReferenceIds.fredRogers]);
      await removeInfluence.execute(InfluenceReferenceIds.fredRogers);

      final signals = await resolveSignals.execute(journey);
      expect(
        signals.narrativeThemeIds,
        contains(NarrativeThemeReferenceIds.leadership),
      );
      expect(
        signals.narrativeThemeIds,
        isNot(contains(NarrativeThemeReferenceIds.love)),
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
