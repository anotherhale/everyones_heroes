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
import 'package:everyonesheroes/features/hero_story/presentation/providers/owner_hero_discoverability_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/my_stories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// HS.FG.3 — Owner Hero discoverability UI on My Stories.
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
          displayName: 'Local Hero',
          languages: [LanguageCode('en')],
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

  Future<void> pumpMyStories(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MyStoriesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('displays Private status and Make Discoverable action',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpMyStories(tester, container);

    expect(
      find.byKey(const ValueKey('hero-discoverability-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-discoverability-status')),
      findsOneWidget,
    );
    expect(find.text('Private'), findsWidgets);
    expect(
      find.text(
        'Your Hero and eligible Stories are not discoverable.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-discoverability-make-discoverable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-discoverability-make-private')),
      findsNothing,
    );
  });

  testWidgets('Make Discoverable updates UI after persistence', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpMyStories(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('hero-discoverability-make-discoverable')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Discoverable'), findsWidgets);
    expect(
      find.text(
        'Your Hero and eligible Stories may appear in Discovery.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-discoverability-make-private')),
      findsOneWidget,
    );
    expect(
      (await heroes.findById(heroId))!.visibility,
      HeroVisibility.public,
    );
  });

  testWidgets('Make Private restores private status after discoverable',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpMyStories(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('hero-discoverability-make-discoverable')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hero-discoverability-make-private')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Private'), findsWidgets);
    expect(
      (await heroes.findById(heroId))!.visibility,
      HeroVisibility.private,
    );
  });

  testWidgets('current state survives provider reload', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpMyStories(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('hero-discoverability-make-discoverable')),
    );
    await tester.pumpAndSettle();

    container.invalidate(ownerHeroDiscoverabilityProvider);
    container.invalidate(ensureActiveLocalHeroProvider);
    await tester.pumpAndSettle();

    expect(find.text('Discoverable'), findsWidgets);
    expect(
      find.byKey(const ValueKey('hero-discoverability-make-private')),
      findsOneWidget,
    );
  });
}
