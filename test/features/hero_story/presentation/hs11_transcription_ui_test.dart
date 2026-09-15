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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_transcription_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/transcription/transcription_store_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/transcription_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryStoryMediaStorageAdapter media;
  late InMemoryCaptureCompletionStore captureStore;
  late InMemoryTranscriptionCompletionStore txCompletion;
  late InMemoryStoryTranscriptionJobStore jobStore;
  late InMemoryEventBus eventBus;
  late HeroId heroId;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    media = InMemoryStoryMediaStorageAdapter();
    captureStore = InMemoryCaptureCompletionStore();
    txCompletion = InMemoryTranscriptionCompletionStore();
    jobStore = InMemoryStoryTranscriptionJobStore();
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

  ProviderContainer buildContainer({
    InMemoryStoryTranscriptionAdapter? transcription,
  }) {
    final store = ActiveLocalHeroStore();
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        storyMediaStoragePortProvider.overrideWithValue(media),
        captureCompletionStoreProvider.overrideWithValue(captureStore),
        transcriptionCompletionStoreProvider.overrideWithValue(txCompletion),
        storyTranscriptionJobStoreProvider.overrideWithValue(jobStore),
        storyTranscriptionPortProvider.overrideWithValue(
          transcription ?? InMemoryStoryTranscriptionAdapter(),
        ),
        eventBusProvider.overrideWithValue(eventBus),
        activeLocalHeroStoreProvider.overrideWithValue(store),
      ],
    );
  }

  Future<StoryId> seedOwnedStory({bool withConsent = false}) async {
    final complete = CompleteStoryCaptureUseCase(
      storyRepository: stories,
      heroRepository: heroes,
      mediaStorage: media,
      eventBus: eventBus,
      completionStore: captureStore,
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
        title: StoryTitle('HS11 Story'),
        occurredAt: DateTime.utc(2026, 9, 15),
      ),
    );
    expect(result, isA<Success>());

    if (withConsent) {
      await UpdateStoryConsentUseCase(
        storyRepository: stories,
        eventBus: eventBus,
      ).execute(
        UpdateStoryConsentRequest(
          storyId: storyId,
          grantProcessing: true,
          grantAiTransformation: true,
        ),
      );
    }
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

  testWidgets('missing consent shows grant path; start hidden', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);
    final storyId = await seedOwnedStory(withConsent: false);

    await pumpDetail(tester, container, storyId);

    expect(
      find.byKey(const ValueKey('owned-story-transcription-heading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('owned-story-transcription-consent-needed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('owned-story-start-transcription-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('owned-story-grant-ai-consent-button')),
      findsOneWidget,
    );
  });

  testWidgets('Start Transcription → completed transcript review',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);
    final storyId = await seedOwnedStory(withConsent: true);

    await pumpDetail(tester, container, storyId);

    expect(
      find.byKey(const ValueKey('owned-story-start-transcription-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('owned-story-start-transcription-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('owned-story-transcript-text')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('owned-story-transcript-label')),
      findsOneWidget,
    );
    expect(find.textContaining('AI-derived transcript'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('owned-story-approve-transcript-button')),
      findsOneWidget,
    );
  });

  testWidgets('failure state exposes retry', (tester) async {
    final container = buildContainer(
      transcription: InMemoryStoryTranscriptionAdapter(
        forcedFailureMessage: 'provider unavailable',
      ),
    );
    addTearDown(container.dispose);
    await container.read(activeLocalHeroStoreProvider).setActive(heroId);
    final storyId = await seedOwnedStory(withConsent: true);

    await pumpDetail(tester, container, storyId);
    await tester.tap(
      find.byKey(const ValueKey('owned-story-start-transcription-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('owned-story-transcription-failure')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('owned-story-retry-transcription-button')),
      findsOneWidget,
    );
  });
}
