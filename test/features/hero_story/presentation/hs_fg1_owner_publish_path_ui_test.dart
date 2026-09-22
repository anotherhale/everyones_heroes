import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// HS.FG.1 — Owner publish path UI composition tests.
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

  Future<StoryId> seedDraftStory({
    String title = 'Publish Path Draft',
  }) async {
    final create = CreateStoryUseCase(
      storyRepository: stories,
      heroRepository: heroes,
      eventBus: eventBus,
    );
    final storyId = StoryId.generate();
    final result = await create.execute(
      CreateStoryRequest(
        storyId: storyId,
        heroId: heroId,
        title: StoryTitle(title),
        narrative: StoryNarrative('A draft ready for the publish path.'),
        originalLanguage: LanguageCode('en'),
        visibility: StoryVisibility.draft,
      ),
    );
    expect(result, isA<Success<Story>>());
    return storyId;
  }

  Future<void> pumpDetail(
    WidgetTester tester,
    ProviderContainer container,
    StoryId storyId,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: OwnedStoryDetailScreen(storyId: storyId.value),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('draft shows Submit and hides Approve/Publish', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final storyId = await seedDraftStory();

    await pumpDetail(tester, container, storyId);

    expect(find.text('Draft'), findsWidgets);
    expect(
      find.byKey(const ValueKey('owned-story-submit-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('owned-story-approve-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('owned-story-publish-button')),
      findsNothing,
    );
  });

  testWidgets('submit → approve → publish updates displayed lifecycle',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final storyId = await seedDraftStory(title: 'Lifecycle UI Story');

    await pumpDetail(tester, container, storyId);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('owned-story-submit-button')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('owned-story-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Submitted'), findsWidgets);
    expect(
      find.byKey(const ValueKey('owned-story-submit-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('owned-story-approve-button')),
      findsOneWidget,
    );
    expect(
      (await stories.findById(storyId))!.lifecycleStatus,
      StoryLifecycleStatus.processing,
    );

    await tester.tap(find.byKey(const ValueKey('owned-story-approve-button')));
    await tester.pumpAndSettle();

    expect(find.text('Approved'), findsWidgets);
    expect(
      find.byKey(const ValueKey('owned-story-approve-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('owned-story-publish-button')),
      findsOneWidget,
    );
    expect(
      (await stories.findById(storyId))!.lifecycleStatus,
      StoryLifecycleStatus.approved,
    );

    await tester.tap(find.byKey(const ValueKey('owned-story-publish-button')));
    await tester.pumpAndSettle();

    expect(find.text('Published'), findsWidgets);
    expect(
      find.byKey(const ValueKey('owned-story-publish-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('owned-story-published-note')),
      findsOneWidget,
    );

    final published = await stories.findById(storyId);
    expect(published!.lifecycleStatus, StoryLifecycleStatus.published);
    expect(published.visibility, StoryVisibility.public);
    expect(published.consent.isPublicationApproved, isTrue);
  });

  testWidgets(
    'failed submit surfaces error and preserves draft for retry',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final storyId = await seedDraftStory(title: 'Fail Submit');

      await pumpDetail(tester, container, storyId);

      // Remove the Story after the detail view model has loaded so Submit fails
      // without corrupting a successful transition.
      await stories.delete(storyId);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('owned-story-submit-button')),
        200,
      );
      await tester.tap(find.byKey(const ValueKey('owned-story-submit-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('owned-story-publication-error')),
        findsOneWidget,
      );
      // Canonical store has no story; UI still shows prior draft actions for retry.
      expect(
        find.byKey(const ValueKey('owned-story-submit-button')),
        findsOneWidget,
      );
      expect(await stories.findById(storyId), isNull);
    },
  );

  testWidgets('persisted lifecycle is restored on reload', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final storyId = await seedDraftStory(title: 'Reload Story');

    await pumpDetail(tester, container, storyId);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('owned-story-submit-button')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('owned-story-submit-button')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpDetail(tester, container, storyId);

    expect(find.text('Submitted'), findsWidgets);
    expect(
      find.byKey(const ValueKey('owned-story-approve-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('owned-story-submit-button')),
      findsNothing,
    );
  });

  testWidgets('published story no longer offers Publish', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final storyId = await seedDraftStory(title: 'Already Published');

    await pumpDetail(tester, container, storyId);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('owned-story-submit-button')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('owned-story-submit-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('owned-story-approve-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('owned-story-publish-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('owned-story-publish-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('owned-story-submit-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('owned-story-approve-button')),
      findsNothing,
    );
  });
}
