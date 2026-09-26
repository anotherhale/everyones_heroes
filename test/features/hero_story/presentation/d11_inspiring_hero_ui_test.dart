import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/discovery_profile_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart'
    hide Hero;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');

  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryDiscoveryProfileRepository profiles;
  late hs.Hero hero;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    profiles = InMemoryDiscoveryProfileRepository();

    hero = hs.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Alex Rivera',
        biography: 'Service and starting over.',
        experienceAreas: const ['Military'],
        languages: [english],
        geographicContext: 'San Antonio',
      ),
      visibility: HeroVisibility.public,
    );
    await heroes.save(hero);
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        discoveryProfileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
  }

  testWidgets('Inspires me toggle reflects current state and persists', (
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

    expect(find.byKey(const Key('inspires-me-unselected')), findsOneWidget);
    expect(find.byKey(const Key('inspires-me-selected')), findsNothing);

    await tester.tap(find.byKey(const Key('inspires-me-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inspires-me-selected')), findsOneWidget);
    expect(find.text('Inspires me ✓'), findsOneWidget);

    // Survive provider refresh of DiscoveryProfile.
    container.invalidate(currentDiscoveryProfileProvider);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inspires-me-selected')), findsOneWidget);

    await tester.tap(find.byKey(const Key('inspires-me-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inspires-me-unselected')), findsOneWidget);
    expect(find.text('Inspires me'), findsOneWidget);
  });

  testWidgets('private Hero profile does not show Inspires me control', (
    tester,
  ) async {
    final privateHero = hs.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Private Hero',
        languages: [english],
      ),
      visibility: HeroVisibility.private,
    );
    await heroes.save(privateHero);

    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: HeroProfileScreen(heroId: privateHero.id.value),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hero-unavailable')), findsOneWidget);
    expect(find.byKey(const Key('inspires-me-toggle')), findsNothing);
  });
}
