import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/my_hero_profile_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/my_stories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// HP.1 / HP.2 — My Hero Profile owner authoring UI.
void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryStoryMediaStorageAdapter media;
  late InMemoryCaptureCompletionStore completionStore;
  late HeroId heroId;
  late InMemoryEventBus eventBus;
  late ActiveLocalHeroStore heroStore;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    media = InMemoryStoryMediaStorageAdapter();
    completionStore = InMemoryCaptureCompletionStore();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    heroStore = ActiveLocalHeroStore();
    heroId = HeroId.generate();
    await heroes.save(
      hs.Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Owner Hero',
          biography: 'Initial biography',
          experienceAreas: const ['Military'],
          languages: [LanguageCode('en')],
          geographicContext: 'Chicago',
        ),
        visibility: HeroVisibility.private,
      ),
    );
    await heroStore.setActive(heroId);
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        storyMediaStoragePortProvider.overrideWithValue(media),
        captureCompletionStoreProvider.overrideWithValue(completionStore),
        eventBusProvider.overrideWithValue(eventBus),
        activeLocalHeroStoreProvider.overrideWithValue(heroStore),
      ],
    );
  }

  Future<void> pumpProfile(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MyHeroProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('My Stories navigates to My Hero Profile', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MyStoriesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('my-stories-open-hero-profile')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('my-stories-open-hero-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(MyHeroProfileScreen), findsOneWidget);
    expect(find.text('My Hero Profile'), findsWidgets);
  });

  testWidgets('loads current profile values into the form', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpProfile(tester, container);

    expect(
      find.byKey(const ValueKey('my-hero-profile-form')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('my-hero-profile-display-name')),
          )
          .controller!
          .text,
      'Owner Hero',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('my-hero-profile-biography')),
          )
          .controller!
          .text,
      'Initial biography',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('my-hero-profile-experience-areas')),
          )
          .controller!
          .text,
      'Military',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('my-hero-profile-geographic-context')),
          )
          .controller!
          .text,
      'Chicago',
    );
    expect(
      find.byKey(const ValueKey('my-hero-profile-language-en')),
      findsOneWidget,
    );
  });

  testWidgets('editing fields and save persists through repository',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpProfile(tester, container);

    await tester.enterText(
      find.byKey(const ValueKey('my-hero-profile-display-name')),
      'Pat Hero',
    );
    await tester.enterText(
      find.byKey(const ValueKey('my-hero-profile-biography')),
      'Updated biography',
    );
    await tester.enterText(
      find.byKey(const ValueKey('my-hero-profile-experience-areas')),
      'Parenting, Leadership',
    );
    await tester.enterText(
      find.byKey(const ValueKey('my-hero-profile-geographic-context')),
      'Seattle',
    );

    await tester.tap(find.byKey(const ValueKey('my-hero-profile-language-es')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('my-hero-profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Profile saved'), findsOneWidget);

    final stored = await heroes.findById(heroId);
    expect(stored!.profile.displayName, 'Pat Hero');
    expect(stored.profile.biography, 'Updated biography');
    expect(stored.profile.experienceAreas, ['Parenting', 'Leadership']);
    expect(stored.profile.geographicContext, 'Seattle');
    expect(
      stored.profile.languages.map((l) => l.value).toSet(),
      {'en', 'es'},
    );
    expect(stored.visibility, HeroVisibility.private);

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('my-hero-profile-display-name')),
          )
          .controller!
          .text,
      'Pat Hero',
    );
  });

  testWidgets('empty display name shows validation error', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpProfile(tester, container);

    await tester.enterText(
      find.byKey(const ValueKey('my-hero-profile-display-name')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey('my-hero-profile-save')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('my-hero-profile-error')),
      findsOneWidget,
    );
    expect(
      (await heroes.findById(heroId))!.profile.displayName,
      'Owner Hero',
    );
  });
}
