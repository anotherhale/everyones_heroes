import 'dart:typed_data';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_catalog_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/my_stories_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryStoryMediaStorageAdapter media;
  late InMemoryCaptureCompletionStore completionStore;
  late HeroId heroId;
  late InMemoryEventBus eventBus;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    media = InMemoryStoryMediaStorageAdapter();
    completionStore = InMemoryCaptureCompletionStore();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
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
  });

  ProviderContainer buildContainer() {
    final store = ActiveLocalHeroStore();
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        storyMediaStoragePortProvider.overrideWithValue(media),
        captureCompletionStoreProvider.overrideWithValue(completionStore),
        eventBusProvider.overrideWithValue(eventBus),
        activeLocalHeroStoreProvider.overrideWithValue(store),
      ],
    );
  }

  Future<StoryId> seedOwnedStory({
    required String title,
    Duration duration = const Duration(minutes: 4, seconds: 32),
  }) async {
    final complete = CompleteStoryCaptureUseCase(
      storyRepository: stories,
      heroRepository: heroes,
      mediaStorage: media,
      eventBus: eventBus,
      completionStore: completionStore,
    );
    final storyId = StoryId.generate();
    final result = await complete.execute(
      CompleteStoryCaptureRequest(
        sessionId: 'session-${storyId.value}',
        heroId: heroId,
        storyId: storyId,
        representationId: StoryRepresentationId.generate(),
        originalLanguage: LanguageCode('en'),
        mediaBytes: Uint8List.fromList(List<int>.filled(32, 3)),
        contentType: 'audio/wav',
        duration: duration,
        title: StoryTitle(title),
        occurredAt: DateTime.utc(2026, 9, 15),
      ),
    );
    expect(result, isA<Success>());
    return storyId;
  }

  Future<void> pumpMyStories(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MyStoriesScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Heroes catalog exposes My Stories entry', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HeroCatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('my-stories-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my-stories-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('my-stories-app-bar')), findsOneWidget);
  });

  testWidgets('empty My Stories state', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);

    await pumpMyStories(tester, container);

    expect(find.byKey(const ValueKey('my-stories-empty-title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('my-stories-empty-tell-story')),
      findsOneWidget,
    );
  });

  testWidgets('populated My Stories shows status and private', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);
    await seedOwnedStory(title: 'Morning Courage');

    await pumpMyStories(tester, container);

    expect(find.text('Morning Courage'), findsOneWidget);
    expect(find.textContaining('Draft'), findsWidgets);
    expect(find.textContaining('Private'), findsWidgets);
    expect(find.textContaining('04:32'), findsOneWidget);
  });

  testWidgets('multiple Stories and navigate to detail with play control', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);
    await seedOwnedStory(title: 'First Story');
    await seedOwnedStory(title: 'Second Story');

    await pumpMyStories(tester, container);
    expect(find.byKey(const ValueKey('my-stories-list')), findsOneWidget);

    await tester.tap(find.text('Second Story'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('owned-story-title')), findsOneWidget);
    expect(find.text('Second Story'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('owned-story-play-button')),
      200,
    );
    expect(find.byKey(const ValueKey('owned-story-play-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('owned-story-privacy-chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('owned-story-lifecycle-chip')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('owned-story-consent-summary')),
      200,
    );
    expect(find.byKey(const ValueKey('owned-story-consent-summary')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('owned-story-archive-button')),
      200,
    );
    expect(find.byKey(const ValueKey('owned-story-archive-button')), findsOneWidget);
  });

  testWidgets('archive removes story from default My Stories', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);
    await seedOwnedStory(title: 'Archive Me');

    await pumpMyStories(tester, container);
    await tester.tap(find.text('Archive Me'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('owned-story-archive-button')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('owned-story-archive-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-archive-button')));
    await tester.pumpAndSettle();

    expect(find.text('Archive Me'), findsNothing);
    expect(find.byKey(const ValueKey('my-stories-empty-title')), findsOneWidget);

    final all = await stories.findAll();
    expect(all, hasLength(1));
    expect(all.first.lifecycleStatus, StoryLifecycleStatus.archived);
    expect(all.first.representations.first.mediaReference, isNotNull);
  });

  testWidgets('owned detail loads independently of Discover', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);
    final storyId = await seedOwnedStory(title: 'Private Detail');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: OwnedStoryDetailScreen(storyId: storyId.value),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Private Detail'), findsOneWidget);
    expect(find.byKey(const ValueKey('owned-story-original-heading')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Play'), 200);
    expect(find.text('Play'), findsOneWidget);
  });
}
