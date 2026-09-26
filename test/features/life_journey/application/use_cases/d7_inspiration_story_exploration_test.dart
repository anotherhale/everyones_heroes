import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/remove_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/select_influences_use_case.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_narrative_theme_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/services/in_memory_influence_theme_resolver.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/explore_stories_by_inspiration_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

/// D.7: Inspiration-grounded Story exploration via NarrativeTheme overlap.
void main() {
  late InMemoryDiscoveryProfileRepository discoveryProfileRepository;
  late InMemoryInfluenceRepository influenceRepository;
  late InMemoryNarrativeThemeRepository narrativeThemeRepository;
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late SelectInfluencesUseCase selectInfluences;
  late RemoveInfluenceUseCase removeInfluence;
  late DefaultExploreStoriesByInspirationUseCase explore;
  late UserId userId;

  setUp(() {
    discoveryProfileRepository = InMemoryDiscoveryProfileRepository();
    influenceRepository = InMemoryInfluenceRepository.withReferenceCatalog();
    narrativeThemeRepository =
        InMemoryNarrativeThemeRepository.withReferenceCatalog();
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    userId = UserId('dev-user');

    final ensure = EnsureCurrentDiscoveryProfileUseCase(
      repository: discoveryProfileRepository,
      currentUserId: userId,
    );
    final resolveThemes = ResolveNarrativeThemesUseCase(
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
      resolveNarrativeThemes: resolveThemes,
      influenceRepository: influenceRepository,
    );
    removeInfluence = RemoveInfluenceUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      repository: discoveryProfileRepository,
      resolveNarrativeThemes: resolveThemes,
    );
    explore = DefaultExploreStoriesByInspirationUseCase(
      ensureCurrentDiscoveryProfile: ensure,
      discoverStories: DiscoverStoriesUseCase(
        storySearchPort: InMemoryStorySearchAdapter(stories),
        storyRepository: stories,
        heroRepository: heroes,
      ),
      narrativeThemeRepository: narrativeThemeRepository,
    );
  });

  test(
    'Test 1 — Inspiration theme produces Story exploration',
    () async {
      final hero = await _seedHero(heroes, name: 'Perseverance Hero');
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Keep Going',
        themes: [NarrativeThemeReferenceIds.perseverance],
      );

      await selectInfluences.execute([InfluenceReferenceIds.rockyBalboa]);

      final result = await explore.execute();

      expect(result.hasInspirations, isTrue);
      expect(
        result.inspirationThemeIds,
        contains(NarrativeThemeReferenceIds.perseverance),
      );
      expect(result.stories.map((s) => s.storyId), contains(story.id));
      expect(
        result.stories.singleWhere((s) => s.storyId == story.id).matchedThemeIds,
        contains(NarrativeThemeReferenceIds.perseverance),
      );
    },
  );

  test('Test 2 — Nonmatching Story excluded', () async {
    final hero = await _seedHero(heroes, name: 'Family Hero');
    final story = await _seedPublishedStory(
      stories,
      hero: hero,
      title: 'Family Bonds',
      themes: [NarrativeThemeReferenceIds.family],
    );

    await selectInfluences.execute([InfluenceReferenceIds.rockyBalboa]);

    final result = await explore.execute();

    expect(result.stories.map((s) => s.storyId), isNot(contains(story.id)));
  });

  test('Test 3 — Multiple Inspirations union correctly', () async {
    final hero = await _seedHero(heroes, name: 'Multi Hero');
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
      title: 'Story B Purpose',
      themes: [NarrativeThemeReferenceIds.purpose],
      createdAt: DateTime.utc(2026, 1, 2),
    );
    final storyC = await _seedPublishedStory(
      stories,
      hero: hero,
      title: 'Story C Family',
      themes: [NarrativeThemeReferenceIds.family],
      createdAt: DateTime.utc(2026, 1, 3),
    );

    // Rocky → courage (+ perseverance, overcoming adversity)
    // Goggins → purpose (+ perseverance, overcoming adversity)
    await selectInfluences.execute([
      InfluenceReferenceIds.rockyBalboa,
      InfluenceReferenceIds.davidGoggins,
    ]);

    final result = await explore.execute();
    final ids = result.stories.map((s) => s.storyId).toSet();

    expect(ids, contains(storyA.id));
    expect(ids, contains(storyB.id));
    expect(ids, isNot(contains(storyC.id)));
  });

  test('Test 4 — Shared theme survives removal', () async {
    final hero = await _seedHero(heroes, name: 'Shared Theme Hero');
    final story = await _seedPublishedStory(
      stories,
      hero: hero,
      title: 'Shared Perseverance',
      themes: [NarrativeThemeReferenceIds.perseverance],
    );

    await selectInfluences.execute([
      InfluenceReferenceIds.rockyBalboa,
      InfluenceReferenceIds.davidGoggins,
    ]);

    await removeInfluence.execute(InfluenceReferenceIds.rockyBalboa);

    final profile = await discoveryProfileRepository.findByUserId(userId);
    expect(
      profile!.containsInfluence(InfluenceReferenceIds.rockyBalboa),
      isFalse,
    );
    expect(
      profile.containsInfluence(InfluenceReferenceIds.davidGoggins),
      isTrue,
    );
    expect(
      profile.containsTheme(NarrativeThemeReferenceIds.perseverance),
      isTrue,
    );

    final result = await explore.execute();
    expect(result.stories.map((s) => s.storyId), contains(story.id));
  });

  test('Test 5 — Exclusive theme disappears', () async {
    final hero = await _seedHero(heroes, name: 'Exclusive Hero');
    final story = await _seedPublishedStory(
      stories,
      hero: hero,
      title: 'Courage Only',
      themes: [NarrativeThemeReferenceIds.courage],
    );

    await selectInfluences.execute([InfluenceReferenceIds.rockyBalboa]);
    var result = await explore.execute();
    expect(result.stories.map((s) => s.storyId), contains(story.id));

    await removeInfluence.execute(InfluenceReferenceIds.rockyBalboa);

    final profile = await discoveryProfileRepository.findByUserId(userId);
    expect(profile!.influenceIds, isEmpty);
    expect(
      profile.containsTheme(NarrativeThemeReferenceIds.courage),
      isFalse,
    );

    result = await explore.execute();
    expect(result.hasInspirations, isFalse);
    expect(result.stories, isEmpty);
  });

  test('Test 6 — Empty Inspirations fabricates nothing', () async {
    final hero = await _seedHero(heroes, name: 'Any Hero');
    await _seedPublishedStory(
      stories,
      hero: hero,
      title: 'Eligible Story',
      themes: [NarrativeThemeReferenceIds.perseverance],
    );

    final result = await explore.execute();

    expect(result.hasInspirations, isFalse);
    expect(result.inspirationThemeIds, isEmpty);
    expect(result.stories, isEmpty);
  });

  test('Test 7 — Eligibility preserved', () async {
    final publicHero = await _seedHero(heroes, name: 'Public Hero');
    final privateHero = await _seedHero(
      heroes,
      name: 'Private Hero',
      visibility: HeroVisibility.private,
    );

    final eligible = await _seedPublishedStory(
      stories,
      hero: publicHero,
      title: 'Public Match',
      themes: [NarrativeThemeReferenceIds.perseverance],
      createdAt: DateTime.utc(2026, 1, 2),
    );
    final ineligibleVisibility = await _seedPublishedStory(
      stories,
      hero: publicHero,
      title: 'Unlisted Match',
      themes: [NarrativeThemeReferenceIds.perseverance],
      visibility: StoryVisibility.unlisted,
      createdAt: DateTime.utc(2026, 1, 3),
    );
    final ineligibleHero = await _seedPublishedStory(
      stories,
      hero: privateHero,
      title: 'Private Hero Match',
      themes: [NarrativeThemeReferenceIds.perseverance],
      createdAt: DateTime.utc(2026, 1, 4),
    );

    await selectInfluences.execute([InfluenceReferenceIds.rockyBalboa]);

    final result = await explore.execute();
    final ids = result.stories.map((s) => s.storyId).toSet();

    expect(ids, contains(eligible.id));
    expect(ids, isNot(contains(ineligibleVisibility.id)));
    expect(ids, isNot(contains(ineligibleHero.id)));
  });

  test(
    'Test 8 — Provenance wording does not claim recent reflection',
    () async {
      final hero = await _seedHero(heroes, name: 'Provenance Hero');
      final story = await _seedPublishedStory(
        stories,
        hero: hero,
        title: 'Perseverance Tale',
        themes: [NarrativeThemeReferenceIds.perseverance],
      );

      await selectInfluences.execute([InfluenceReferenceIds.rockyBalboa]);

      final result = await explore.execute();
      final grounded = result.stories.singleWhere((s) => s.storyId == story.id);

      expect(grounded.relevanceLabel.toLowerCase(), contains('perseverance'));
      expect(grounded.relevanceLabel.toLowerCase(), isNot(contains('reflect')));
      expect(
        grounded.relevanceLabel.toLowerCase(),
        isNot(contains('recently')),
      );
      expect(grounded.relevanceLabel, startsWith('Connected through'));
    },
  );
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
      experienceAreas: const ['Service'],
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
  List<NarrativeThemeId> themes = const [],
  StoryVisibility visibility = StoryVisibility.public,
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
    ..changeVisibility(visibility)
    ..publish(at: createdAt);
  await stories.save(story);
  return story;
}
