import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/browse_stories_by_catalog_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_heroes_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_discovery_summary_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_heroes_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_discovery_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/browse_stories_by_catalog_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_heroes_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_discovery_summary_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_hero_search_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');
  final spanish = LanguageCode('es');
  final themeId = NarrativeThemeId('courage');

  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late DiscoverStoriesUseCase discoverStories;
  late DiscoverHeroesUseCase discoverHeroes;
  late BrowseStoriesByCatalogUseCase browseStories;
  late GetStoryDiscoverySummaryUseCase getSummary;

  setUp(() {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    final storySearch = InMemoryStorySearchAdapter(stories);
    final heroSearch = InMemoryHeroSearchAdapter(heroes);
    discoverStories = DiscoverStoriesUseCase(
      storySearchPort: storySearch,
      storyRepository: stories,
      heroRepository: heroes,
    );
    discoverHeroes = DiscoverHeroesUseCase(
      heroSearchPort: heroSearch,
      heroRepository: heroes,
    );
    browseStories = BrowseStoriesByCatalogUseCase(
      discoverStoriesUseCase: discoverStories,
    );
    getSummary = GetStoryDiscoverySummaryUseCase(
      storyRepository: stories,
      heroRepository: heroes,
    );
  });

  Future<Hero> seedHero({
    required String name,
    HeroVisibility visibility = HeroVisibility.public,
    HeroStatus status = HeroStatus.active,
    DateTime? createdAt,
    List<String> experienceAreas = const ['Military'],
  }) async {
    final hero = Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: name,
        biography: 'Lived experience.',
        experienceAreas: experienceAreas,
        languages: [english],
      ),
      visibility: visibility,
      createdAt: createdAt,
    );
    if (status == HeroStatus.archived) {
      hero.archive();
    }
    await heroes.save(hero);
    return hero;
  }

  Future<Story> seedPublishedStory({
    required Hero hero,
    required String title,
    StoryVisibility visibility = StoryVisibility.public,
    StoryClassification? classification,
    List<StoryRepresentation> representations = const [],
    DateTime? createdAt,
    LanguageCode? originalLanguage,
  }) async {
    final story = Story.create(
      id: StoryId.generate(),
      heroId: hero.id,
      title: StoryTitle(title),
      narrative: StoryNarrative('A published lived experience for $title.'),
      originalLanguage: originalLanguage ?? english,
      createdAt: createdAt,
    );
    if (classification != null) {
      story.classify(classification);
    }
    for (final representation in representations) {
      story.addRepresentation(representation);
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

  group('visibility eligibility (D2)', () {
    test('public and community stories are discoverable', () async {
      final hero = await seedHero(name: 'Public Hero');
      final publicStory = await seedPublishedStory(
        hero: hero,
        title: 'Public Story',
        visibility: StoryVisibility.public,
      );
      final communityStory = await seedPublishedStory(
        hero: hero,
        title: 'Community Story',
        visibility: StoryVisibility.community,
      );

      final result = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      expect(result, isA<Success<DiscoverStoriesResponse>>());
      final ids = (result as Success<DiscoverStoriesResponse>).value.items
          .map((item) => item.storyId)
          .toSet();
      expect(ids, containsAll([publicStory.id, communityStory.id]));
    });

    test('private and unlisted stories are excluded', () async {
      final hero = await seedHero(name: 'Hero');
      await seedPublishedStory(
        hero: hero,
        title: 'Unlisted Story',
        visibility: StoryVisibility.unlisted,
      );
      final draft = Story.create(
        id: StoryId.generate(),
        heroId: hero.id,
        title: StoryTitle('Draft Story'),
        narrative: StoryNarrative('Still private draft narrative.'),
        originalLanguage: english,
      );
      await stories.save(draft);

      // Manually force a private published-looking path is not allowed by
      // domain; ensure unpublished draft is excluded and unlisted is excluded.
      final result = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      final response = (result as Success<DiscoverStoriesResponse>).value;
      expect(response.items, isEmpty);
      expect(response.totalCount, 0);
    });

    test('private and unlisted heroes are excluded from hero discovery', () async {
      await seedHero(name: 'Private', visibility: HeroVisibility.private);
      await seedHero(name: 'Unlisted', visibility: HeroVisibility.unlisted);
      final publicHero = await seedHero(
        name: 'Public',
        visibility: HeroVisibility.public,
      );
      final communityHero = await seedHero(
        name: 'Community',
        visibility: HeroVisibility.community,
      );

      final result = await discoverHeroes.execute(const DiscoverHeroesRequest());
      final ids = (result as Success<DiscoverHeroesResponse>).value.items
          .map((item) => item.heroId)
          .toSet();
      expect(ids, {publicHero.id, communityHero.id});
    });

    test('story with private hero is not discoverable', () async {
      final privateHero = await seedHero(
        name: 'Hidden',
        visibility: HeroVisibility.private,
      );
      await seedPublishedStory(
        hero: privateHero,
        title: 'Orphan Leak Candidate',
        visibility: StoryVisibility.public,
      );

      final result = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      expect((result as Success<DiscoverStoriesResponse>).value.items, isEmpty);
    });

    test('get summary rejects unlisted known ids', () async {
      final hero = await seedHero(name: 'Hero');
      final unlisted = await seedPublishedStory(
        hero: hero,
        title: 'Unlisted Known',
        visibility: StoryVisibility.unlisted,
      );

      final result = await getSummary.execute(
        GetStoryDiscoverySummaryRequest(storyId: unlisted.id),
      );
      expect(result, isA<Failure<StoryDiscoverySummary>>());
    });
  });

  group('authoritative representations (D3)', () {
    test('unapproved AI format does not satisfy format filter', () async {
      final hero = await seedHero(name: 'Author');
      final originalId = StoryRepresentationId.generate();
      await seedPublishedStory(
        hero: hero,
        title: 'AI Script Draft',
        classification: StoryClassification(
          subjects: const [StorySubject.military],
        ),
        representations: [
          StoryRepresentation(
            id: originalId,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://audio'),
            duration: const Duration(minutes: 10),
          ),
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.script,
            origin: RepresentationOrigin.derived,
            sourceRepresentationId: originalId,
            textContent: 'Generated script body',
            isAiGenerated: true,
            isApproved: false,
          ),
        ],
      );

      final result = await discoverStories.execute(
        const DiscoverStoriesRequest(
          formats: [StoryRepresentationFormat.script],
        ),
      );
      expect((result as Success<DiscoverStoriesResponse>).value.items, isEmpty);
    });

    test('approved AI format satisfies format filter', () async {
      final hero = await seedHero(name: 'Author');
      final originalId = StoryRepresentationId.generate();
      final scriptId = StoryRepresentationId.generate();
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Approved Script Story',
        classification: StoryClassification(
          subjects: const [StorySubject.military],
        ),
        representations: [
          StoryRepresentation(
            id: originalId,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://audio'),
          ),
          StoryRepresentation(
            id: scriptId,
            language: english,
            format: StoryRepresentationFormat.script,
            origin: RepresentationOrigin.derived,
            sourceRepresentationId: originalId,
            textContent: 'Generated script body',
            isAiGenerated: true,
            isApproved: false,
          ),
        ],
      );

      story.approveRepresentation(scriptId);
      await stories.save(story);

      final result = await discoverStories.execute(
        const DiscoverStoriesRequest(
          formats: [StoryRepresentationFormat.script],
        ),
      );
      final items = (result as Success<DiscoverStoriesResponse>).value.items;
      expect(items.map((item) => item.storyId), [story.id]);
      expect(
        items.single.authoritativeRepresentations.map((r) => r.format),
        contains(StoryRepresentationFormat.script),
      );
    });

    test('unapproved translation language does not satisfy availableLanguage', () async {
      final hero = await seedHero(name: 'Author');
      final originalId = StoryRepresentationId.generate();
      await seedPublishedStory(
        hero: hero,
        title: 'Pending Translation',
        originalLanguage: english,
        representations: [
          StoryRepresentation(
            id: originalId,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://en'),
          ),
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: spanish,
            format: StoryRepresentationFormat.written,
            origin: RepresentationOrigin.translated,
            sourceRepresentationId: originalId,
            textContent: 'Spanish draft',
            isAiGenerated: true,
            isApproved: false,
          ),
        ],
      );

      final result = await discoverStories.execute(
        DiscoverStoriesRequest(availableLanguage: spanish),
      );
      expect((result as Success<DiscoverStoriesResponse>).value.items, isEmpty);
    });

    test('summaries never include unapproved representation text bodies', () async {
      final hero = await seedHero(name: 'Author');
      final originalId = StoryRepresentationId.generate();
      await seedPublishedStory(
        hero: hero,
        title: 'Safe Summary',
        representations: [
          StoryRepresentation(
            id: originalId,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://audio'),
          ),
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.script,
            origin: RepresentationOrigin.derived,
            sourceRepresentationId: originalId,
            textContent: 'SECRET_UNAPPROVED_SCRIPT',
            isAiGenerated: true,
            isApproved: false,
          ),
        ],
      );

      final result = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      final summary =
          (result as Success<DiscoverStoriesResponse>).value.items.single;
      expect(summary.title, 'Safe Summary');
      expect(
        summary.authoritativeRepresentations.map((r) => r.format),
        isNot(contains(StoryRepresentationFormat.script)),
      );
      // Ensure no narrative body exposure either (D9).
      expect(summary.toString().contains('SECRET_UNAPPROVED_SCRIPT'), isFalse);
    });
  });

  group('search / filters / browse', () {
    test('text search matches eligible stories only', () async {
      final hero = await seedHero(name: 'Hero');
      final match = await seedPublishedStory(
        hero: hero,
        title: 'Resilience Journey',
      );
      await seedPublishedStory(hero: hero, title: 'Other Tale');

      final result = await discoverStories.execute(
        const DiscoverStoriesRequest(text: 'resilience'),
      );
      final items = (result as Success<DiscoverStoriesResponse>).value.items;
      expect(items.map((item) => item.storyId), [match.id]);
      expect(items.single.matchReasons, contains(DiscoveryMatchReason.text));
    });

    test('combined subject and theme filters use AND semantics', () async {
      final hero = await seedHero(name: 'Hero');
      final match = await seedPublishedStory(
        hero: hero,
        title: 'Both',
        classification: StoryClassification(
          subjects: const [StorySubject.military],
          narrativeThemeIds: [themeId],
        ),
      );
      await seedPublishedStory(
        hero: hero,
        title: 'Subject Only',
        classification: StoryClassification(
          subjects: const [StorySubject.military],
        ),
      );

      final result = await discoverStories.execute(
        DiscoverStoriesRequest(
          subjects: const [StorySubject.military],
          narrativeThemeIds: [themeId],
        ),
      );
      expect(
        (result as Success<DiscoverStoriesResponse>).value.items
            .map((item) => item.storyId),
        [match.id],
      );
    });

    test('empty catalog discovery returns empty success', () async {
      final result = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      final response = (result as Success<DiscoverStoriesResponse>).value;
      expect(response.items, isEmpty);
      expect(response.totalCount, 0);
      expect(response.nextOffset, isNull);
    });

    test('browse by subject uses discovery eligibility', () async {
      final hero = await seedHero(name: 'Hero');
      final match = await seedPublishedStory(
        hero: hero,
        title: 'Military Public',
        classification: StoryClassification(
          subjects: const [StorySubject.military],
        ),
      );
      await seedPublishedStory(
        hero: hero,
        title: 'Military Unlisted',
        visibility: StoryVisibility.unlisted,
        classification: StoryClassification(
          subjects: const [StorySubject.military],
        ),
      );

      final result = await browseStories.execute(
        const BrowseStoriesByCatalogRequest(
          dimension: CatalogBrowseDimension.subject,
          subject: StorySubject.military,
        ),
      );
      expect(
        (result as Success<DiscoverStoriesResponse>).value.items
            .map((item) => item.storyId),
        [match.id],
      );
    });

    test('browse by format ignores unapproved scripts', () async {
      final hero = await seedHero(name: 'Hero');
      final originalId = StoryRepresentationId.generate();
      await seedPublishedStory(
        hero: hero,
        title: 'Unapproved Script Only',
        representations: [
          StoryRepresentation(
            id: originalId,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://audio'),
          ),
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.script,
            origin: RepresentationOrigin.derived,
            sourceRepresentationId: originalId,
            textContent: 'draft',
            isAiGenerated: true,
            isApproved: false,
          ),
        ],
      );

      final result = await browseStories.execute(
        const BrowseStoriesByCatalogRequest(
          dimension: CatalogBrowseDimension.format,
          format: StoryRepresentationFormat.script,
        ),
      );
      expect((result as Success<DiscoverStoriesResponse>).value.items, isEmpty);
    });

    test('browse missing dimension value fails', () async {
      final result = await browseStories.execute(
        const BrowseStoriesByCatalogRequest(
          dimension: CatalogBrowseDimension.subject,
        ),
      );
      expect(result, isA<Failure<DiscoverStoriesResponse>>());
    });
  });

  group('deterministic ordering and pagination', () {
    test('stories order by updatedAt desc then storyId asc', () async {
      final hero = await seedHero(name: 'Hero');
      final older = await seedPublishedStory(
        hero: hero,
        title: 'Older',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final newer = await seedPublishedStory(
        hero: hero,
        title: 'Newer',
        createdAt: DateTime.utc(2026, 2, 1),
      );

      // Same updatedAt tie-break via id: create two with identical timestamps.
      final t = DateTime.utc(2026, 3, 1);
      final a = Story.create(
        id: StoryId('story-a'),
        heroId: hero.id,
        title: StoryTitle('A'),
        narrative: StoryNarrative('Narrative A for ordering.'),
        originalLanguage: english,
        createdAt: t,
      );
      final b = Story.create(
        id: StoryId('story-b'),
        heroId: hero.id,
        title: StoryTitle('B'),
        narrative: StoryNarrative('Narrative B for ordering.'),
        originalLanguage: english,
        createdAt: t,
      );
      for (final story in [a, b]) {
        story.updateConsent(
          story.consent
              .grantProcessing(DateTime.utc(2026, 1, 1))
              .grantPublication(DateTime.utc(2026, 1, 1)),
        );
        story
          ..submit(at: t)
          ..markReadyForReview(at: t)
          ..approve(at: t)
          ..changeVisibility(StoryVisibility.public)
          ..publish(at: t);
        await stories.save(story);
      }

      final first = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      final second = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      final firstIds = (first as Success<DiscoverStoriesResponse>).value.items
          .map((item) => item.storyId.value)
          .toList();
      final secondIds = (second as Success<DiscoverStoriesResponse>).value.items
          .map((item) => item.storyId.value)
          .toList();
      expect(firstIds, secondIds);
      expect(firstIds.take(2).toList(), ['story-a', 'story-b']);
      expect(firstIds.contains(newer.id.value), isTrue);
      expect(firstIds.contains(older.id.value), isTrue);
      expect(firstIds.indexOf(newer.id.value) < firstIds.indexOf(older.id.value), isTrue);
      final indexA = firstIds.indexOf('story-a');
      final indexB = firstIds.indexOf('story-b');
      expect(indexA < indexB, isTrue);
    });

    test('heroes order by createdAt desc then heroId asc', () async {
      final older = await seedHero(
        name: 'Older',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final newer = await seedHero(
        name: 'Newer',
        createdAt: DateTime.utc(2026, 2, 1),
      );

      final result = await discoverHeroes.execute(const DiscoverHeroesRequest());
      final ids = (result as Success<DiscoverHeroesResponse>).value.items
          .map((item) => item.heroId)
          .toList();
      expect(ids.first, newer.id);
      expect(ids.last, older.id);
    });

    test('pagination returns stable windows and nextOffset', () async {
      final hero = await seedHero(name: 'Hero');
      for (var i = 0; i < 5; i++) {
        await seedPublishedStory(
          hero: hero,
          title: 'Story $i',
          createdAt: DateTime.utc(2026, 1, i + 1),
        );
      }

      final page1 = await discoverStories.execute(
        const DiscoverStoriesRequest(limit: 2, offset: 0),
      );
      final response1 = (page1 as Success<DiscoverStoriesResponse>).value;
      expect(response1.items, hasLength(2));
      expect(response1.totalCount, 5);
      expect(response1.nextOffset, 2);

      final page2 = await discoverStories.execute(
        const DiscoverStoriesRequest(limit: 2, offset: 2),
      );
      final response2 = (page2 as Success<DiscoverStoriesResponse>).value;
      expect(response2.items, hasLength(2));
      expect(response2.nextOffset, 4);

      final page3 = await discoverStories.execute(
        const DiscoverStoriesRequest(limit: 2, offset: 4),
      );
      final response3 = (page3 as Success<DiscoverStoriesResponse>).value;
      expect(response3.items, hasLength(1));
      expect(response3.nextOffset, isNull);

      final allIds = {
        ...response1.items.map((item) => item.storyId.value),
        ...response2.items.map((item) => item.storyId.value),
        ...response3.items.map((item) => item.storyId.value),
      };
      expect(allIds, hasLength(5));
    });
  });

  group('mutation and providers', () {
    test('discover does not mutate stories or raise events', () async {
      final hero = await seedHero(name: 'Hero');
      final story = await seedPublishedStory(hero: hero, title: 'Stable');
      story.pullDomainEvents();
      final beforeUpdated = story.updatedAt;
      final beforeLifecycle = story.lifecycleStatus;

      await discoverStories.execute(const DiscoverStoriesRequest());

      final reloaded = await stories.findById(story.id);
      expect(reloaded!.updatedAt, beforeUpdated);
      expect(reloaded.lifecycleStatus, beforeLifecycle);
      expect(reloaded.pullDomainEvents(), isEmpty);
    });

    test('riverpod providers resolve discovery use cases', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(discoverStoriesUseCaseProvider), isNotNull);
      expect(container.read(discoverHeroesUseCaseProvider), isNotNull);
      expect(container.read(browseStoriesByCatalogUseCaseProvider), isNotNull);
      expect(
        container.read(getStoryDiscoverySummaryUseCaseProvider),
        isNotNull,
      );
      expect(container.read(searchStoriesUseCaseProvider), isNotNull);
      expect(container.read(searchHeroesUseCaseProvider), isNotNull);
    });

    test('archived heroes are excluded', () async {
      await seedHero(name: 'Archived', status: HeroStatus.archived);
      final result = await discoverHeroes.execute(const DiscoverHeroesRequest());
      expect((result as Success<DiscoverHeroesResponse>).value.items, isEmpty);
    });
  });
}
