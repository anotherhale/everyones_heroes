import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/app/presentation/theme/app_theme.dart';
import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/captured_story_reading_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_experience_planner_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_transcription_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/original_recording_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/captured_story_reading_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/transcription/transcription_store_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/transcription_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_experience_planner_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/fake_original_recording_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_experience_plan_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_understanding_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/tell_your_story_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/tell_your_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryStoryMediaStorageAdapter media;
  late InMemoryCaptureCompletionStore completionStore;
  late InMemoryStoryTranscriptionJobStore jobStore;
  late InMemoryTranscriptionCompletionStore transcriptionCompletionStore;
  late InMemoryCapturedStoryReadingRepository readings;
  late InMemoryStoryExperiencePlanRepository plans;
  late InMemoryStoryTranscriptionAdapter transcriptionAdapter;
  late CapturedStoryReadingPort readingAdapter;
  late StoryExperiencePlannerPort plannerAdapter;
  late FakeDeviceRecordingAdapter recorder;
  late FakeOriginalRecordingPlayer player;
  late Directory tempDir;
  late HeroId heroId;

  const heroName = 'Local Hero';
  const storyTitle = 'Stepping Forward';

  setUp(() async {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    media = InMemoryStoryMediaStorageAdapter();
    completionStore = InMemoryCaptureCompletionStore();
    jobStore = InMemoryStoryTranscriptionJobStore();
    transcriptionCompletionStore = InMemoryTranscriptionCompletionStore();
    readings = InMemoryCapturedStoryReadingRepository();
    plans = InMemoryStoryExperiencePlanRepository();
    transcriptionAdapter = InMemoryStoryTranscriptionAdapter();
    readingAdapter = InMemoryCapturedStoryReadingAdapter();
    plannerAdapter = InMemoryStoryExperiencePlannerAdapter();
    tempDir = Directory.systemTemp.createTempSync('hs12-4-ui-');
    recorder = FakeDeviceRecordingAdapter(
      outputDirectory: tempDir,
      initialPermission: DevicePermissionStatus.granted,
      fakeBytes: 'original-captured-recording',
    );
    player = FakeOriginalRecordingPlayer();
    heroId = HeroId.generate();

    await heroes.save(
      hs.Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: heroName,
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      ),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        storyMediaStoragePortProvider.overrideWithValue(media),
        captureCompletionStoreProvider.overrideWithValue(completionStore),
        storyTranscriptionJobStoreProvider.overrideWithValue(jobStore),
        transcriptionCompletionStoreProvider.overrideWithValue(
          transcriptionCompletionStore,
        ),
        capturedStoryReadingRepositoryProvider.overrideWithValue(readings),
        storyExperiencePlanRepositoryProvider.overrideWithValue(plans),
        storyTranscriptionPortProvider.overrideWithValue(transcriptionAdapter),
        capturedStoryReadingPortProvider.overrideWithValue(readingAdapter),
        storyExperiencePlannerPortProvider.overrideWithValue(plannerAdapter),
        eventBusProvider.overrideWithValue(
          InMemoryEventBus(
            eventStore: InMemoryEventStore(),
            dispatcher: InMemoryEventDispatcher(),
          ),
        ),
        useRealDeviceRecordingProvider.overrideWithValue(false),
        deviceRecordingPortProvider.overrideWithValue(recorder),
        activeLocalHeroStoreProvider.overrideWithValue(ActiveLocalHeroStore()),
        originalRecordingPlayerFactoryProvider.overrideWithValue(
          FakeOriginalRecordingPlayerFactory(player),
        ),
      ],
    );
  }

  Future<void> captureThroughHeroStory(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const _PreviousScreen(),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-tell-your-story')));
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        final phase = container.read(tellYourStoryControllerProvider).phase;
        if (phase.name != 'idle') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      final controller = container.read(
        tellYourStoryControllerProvider.notifier,
      );
      controller.continueToRecord();
      await controller.startRecording();
      await controller.stopRecording();
      controller.updateTitle(storyTitle);
      await controller.acceptRecording();
      controller.setGrantProcessing(true);
      controller.setGrantAiTransformation(true);
      await controller.submitConsent();
    });
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('capture-view-story-button')));
    await tester.pumpAndSettle();
  }

  Future<String> understandStory(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    final storyId = (await stories.findAll()).single.id.value;
    await tester.tap(find.byKey(const ValueKey('hero-story-understand-button')));
    await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        final phase =
            container.read(heroStoryUnderstandingProvider(storyId)).phase;
        if (phase == HeroStoryUnderstandingPhase.ready ||
            phase == HeroStoryUnderstandingPhase.failed) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();
    return storyId;
  }

  testWidgets('idle: Create my experience appears only after reading',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    expect(find.text('Create my experience'), findsNothing);
    expect(find.text('Play my recording'), findsOneWidget);

    final storyId = await understandStory(tester, container);
    expect(
      container.read(heroStoryUnderstandingProvider(storyId)).phase,
      HeroStoryUnderstandingPhase.ready,
    );
    expect(find.text('Create my experience'), findsOneWidget);
    expect(
      container.read(heroStoryExperiencePlanProvider(storyId)).phase,
      HeroStoryExperiencePlanPhase.idle,
    );
  });

  testWidgets('success state shows grounded plan summary', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    final storyId = await understandStory(tester, container);

    await tester.ensureVisible(
      find.byKey(const ValueKey('hero-story-create-experience-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('hero-story-create-experience-button')),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        final phase =
            container.read(heroStoryExperiencePlanProvider(storyId)).phase;
        if (phase == HeroStoryExperiencePlanPhase.success ||
            phase == HeroStoryExperiencePlanPhase.failed) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(
      container.read(heroStoryExperiencePlanProvider(storyId)).phase,
      HeroStoryExperiencePlanPhase.success,
    );
    expect(
      find.byKey(const ValueKey('hero-story-experience-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-story-experience-intention')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-story-experience-core-message')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-story-experience-reflection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hero-story-experience-music')),
      findsOneWidget,
    );
    expect(find.text('Play my recording'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.pumpAndSettle();
    expect(player.calls, containsAllInOrder(<String>['load', 'play']));
  });

  testWidgets('failure keeps recording playable and supports retry', (
    tester,
  ) async {
    final toggle = _TogglePlannerPort();
    plannerAdapter = toggle;
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    final storyId = await understandStory(tester, container);

    await tester.ensureVisible(
      find.byKey(const ValueKey('hero-story-create-experience-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('hero-story-create-experience-button')),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        final phase =
            container.read(heroStoryExperiencePlanProvider(storyId)).phase;
        if (phase == HeroStoryExperiencePlanPhase.failed) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hero-story-experience-error')),
      findsOneWidget,
    );
    expect(find.text('Retry experience plan'), findsOneWidget);
    expect(find.text('Play my recording'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hero-story-experience-section')),
      findsNothing,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.pumpAndSettle();
    expect(player.calls, containsAllInOrder(<String>['load', 'play']));

    toggle.fail = false;
    await tester.tap(
      find.byKey(const ValueKey('hero-story-create-experience-button')),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        final phase =
            container.read(heroStoryExperiencePlanProvider(storyId)).phase;
        if (phase == HeroStoryExperiencePlanPhase.success) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hero-story-experience-section')),
      findsOneWidget,
    );
    expect(find.text('Play my recording'), findsOneWidget);
  });
}

final class _TogglePlannerPort implements StoryExperiencePlannerPort {
  bool fail = true;
  final InMemoryStoryExperiencePlannerAdapter _ok =
      InMemoryStoryExperiencePlannerAdapter();

  @override
  Future<StoryExperiencePlanDraft> generate({
    required Story story,
    required CapturedStoryReading reading,
    required String transcriptText,
  }) {
    if (fail) {
      throw const StoryExperiencePlannerException('temporary');
    }
    return _ok.generate(
      story: story,
      reading: reading,
      transcriptText: transcriptText,
    );
  }
}

class _PreviousScreen extends StatelessWidget {
  const _PreviousScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: const ValueKey('open-tell-your-story'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TellYourStoryScreen(),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}
