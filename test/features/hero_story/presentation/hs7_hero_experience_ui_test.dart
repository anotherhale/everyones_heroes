import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_heroes_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_heroes_response.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart'
    hide Hero;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_catalog_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_profile_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_consume_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');

  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late hs.Hero hero;
  late Story story;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();

    hero = hs.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Alex Rivera',
        biography: 'Service and starting over.',
        experienceAreas: const ['Military'],
        languages: [english],
      ),
      visibility: HeroVisibility.public,
    );
    await heroes.save(hero);

    story = Story.create(
      id: StoryId.generate(),
      heroId: hero.id,
      title: StoryTitle('Finding Forward'),
      narrative: StoryNarrative('I chose courage one ordinary morning.'),
      originalLanguage: english,
    );
    story.addRepresentation(
      StoryRepresentation(
        id: StoryRepresentationId('written-en'),
        language: english,
        format: StoryRepresentationFormat.written,
        origin: RepresentationOrigin.original,
        textContent: 'I chose courage one ordinary morning.',
      ),
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
      ..changeVisibility(StoryVisibility.public)
      ..publish();
    await stories.save(story);
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
      ],
    );
  }

  testWidgets('Hero catalog lists discoverable heroes', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HeroCatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.byKey(ValueKey('hero-tile-${hero.id.value}')), findsOneWidget);
  });

  testWidgets('Hero profile shows stories and opens story detail', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: HeroProfileScreen(heroId: hero.id.value)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hero-profile-name')), findsOneWidget);
    expect(find.text('Finding Forward'), findsOneWidget);

    await tester.tap(find.text('Finding Forward'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('story-narrative-body')), findsOneWidget);
    expect(
      find.text('I chose courage one ordinary morning.'),
      findsWidgets,
    );
  });

  testWidgets('Story detail begin opens consume without reflection', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: StoryDetailScreen(storyId: story.id.value)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('begin-story-consume')));
    await tester.pumpAndSettle();

    expect(find.byType(StoryConsumeScreen), findsOneWidget);
    expect(find.byKey(const Key('consume-text')), findsOneWidget);
    expect(find.byKey(const Key('reflect-on-story')), findsOneWidget);
  });

  test('discover heroes provider uses Discover* path', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    final result = await container
        .read(discoverHeroesUseCaseProvider)
        .execute(const DiscoverHeroesRequest());
    expect(result, isA<Success<DiscoverHeroesResponse>>());
    expect(
      (result as Success<DiscoverHeroesResponse>).value.items.first.displayName,
      'Alex Rivera',
    );
  });
}
