import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/app/presentation/theme/app_theme.dart';
import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/captured_story_reading_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_experience_planner_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_transcription_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/voice_rendering_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/original_recording_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/story_experience_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/captured_story_reading_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_voice_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/transcription/transcription_store_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/transcription_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_experience_planner_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_voice_rendering_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/fake_original_recording_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/fake_story_experience_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_voice_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_experience_plan_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_understanding_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_voice_rendering_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/tell_your_story_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_story_screen.dart';
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
  late InMemoryStoryVoiceRenderingRepository voiceRenderings;
  late InMemoryStoryTranscriptionAdapter transcriptionAdapter;
  late CapturedStoryReadingPort readingAdapter;
  late StoryExperiencePlannerPort plannerAdapter;
  late InMemoryVoiceRenderingAdapter voiceAdapter;
  late FakeDeviceRecordingAdapter recorder;
  late FakeOriginalRecordingPlayer originalPlayer;
  late FakeStoryExperiencePlayer experiencePlayer;
  late Directory tempDir;
  late HeroId heroId;

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
    voiceRenderings = InMemoryStoryVoiceRenderingRepository();
    transcriptionAdapter = InMemoryStoryTranscriptionAdapter();
    readingAdapter = InMemoryCapturedStoryReadingAdapter();
    plannerAdapter = InMemoryStoryExperiencePlannerAdapter();
    voiceAdapter = InMemoryVoiceRenderingAdapter(
      audioBytes: Uint8List.fromList(utf8.encode('narrated-audio')),
      contentType: 'audio/mpeg',
    );
    tempDir = Directory.systemTemp.createTempSync('hs12-6-ui-');
    recorder = FakeDeviceRecordingAdapter(
      outputDirectory: tempDir,
      initialPermission: DevicePermissionStatus.granted,
      fakeBytes: 'original-captured-recording',
    );
    originalPlayer = FakeOriginalRecordingPlayer();
    experiencePlayer = FakeStoryExperiencePlayer();
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

  tearDown(() async {
    await experiencePlayer.dispose();
    await originalPlayer.dispose();
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
        storyVoiceRenderingRepositoryProvider.overrideWithValue(voiceRenderings),
        storyTranscriptionPortProvider.overrideWithValue(transcriptionAdapter),
        capturedStoryReadingPortProvider.overrideWithValue(readingAdapter),
        storyExperiencePlannerPortProvider.overrideWithValue(plannerAdapter),
        voiceRenderingPortProvider.overrideWithValue(voiceAdapter),
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
          FakeOriginalRecordingPlayerFactory(originalPlayer),
        ),
        storyExperiencePlayerFactoryProvider.overrideWithValue(
          FakeStoryExperiencePlayerFactory(experiencePlayer),
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

  Future<String> understandAndCreateExperience(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    final storyId = (await stories.findAll()).single.id.value;
    await tester.tap(
      find.byKey(const ValueKey('hero-story-understand-button')),
    );
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

    await tester.drag(
      find.byKey(const ValueKey('hero-story-screen')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
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
    return storyId;
  }

  testWidgets('requires voice consent before Create narrated version',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    final storyId = await understandAndCreateExperience(tester, container);

    await tester.drag(
      find.byKey(const ValueKey('hero-story-screen')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hero-story-voice-section')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hero-story-voice-consent-needed')),
      findsOneWidget,
    );
    final createButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('hero-story-create-narrated-button')),
    );
    expect(createButton.onPressed, isNull);
    expect(voiceAdapter.callCount, 0);

    await tester.tap(
      find.byKey(const ValueKey('hero-story-voice-grant-consent-button')),
    );
    await tester.pumpAndSettle();

    final enabled = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('hero-story-create-narrated-button')),
    );
    expect(enabled.onPressed, isNotNull);

    final story = await stories.findById(StoryId(storyId));
    expect(story!.consent.isVoiceRenderingApproved, isTrue);
  });

  testWidgets('create + play narrated version does not regenerate on play',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    final storyId = await understandAndCreateExperience(tester, container);

    await tester.drag(
      find.byKey(const ValueKey('hero-story-screen')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hero-story-voice-grant-consent-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hero-story-create-narrated-button')),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        final phase =
            container.read(heroStoryVoiceRenderingProvider(storyId)).phase;
        if (phase == HeroStoryVoiceRenderingPhase.ready ||
            phase == HeroStoryVoiceRenderingPhase.failed) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(voiceAdapter.callCount, 1);
    expect(
      find.byKey(const ValueKey('hero-story-play-narrated-button')),
      findsOneWidget,
    );
    expect(find.text('Synthetic narration'), findsOneWidget);
    expect(await voiceRenderings.findByStoryId(StoryId(storyId)), isNotNull);

    await tester.tap(
      find.byKey(const ValueKey('hero-story-play-narrated-button')),
    );
    await tester.pumpAndSettle();
    expect(voiceAdapter.callCount, 1);
    expect(originalPlayer.calls, contains('load'));
    expect(originalPlayer.calls, contains('play'));

    await tester.tap(
      find.byKey(const ValueKey('hero-story-play-narrated-button')),
    );
    await tester.pumpAndSettle();
    expect(originalPlayer.calls, contains('pause'));

    await container
        .read(heroStoryVoiceRenderingProvider(storyId).notifier)
        .stop();
    await tester.pumpAndSettle();
    expect(originalPlayer.calls, contains('stop'));
    expect(voiceAdapter.callCount, 1);
  });

  testWidgets('original recording and experience remain available',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    await understandAndCreateExperience(tester, container);

    expect(find.byType(HeroStoryScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hero-story-play-experience-button')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hero-story-screen')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hero-story-create-narrated-button')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hero-story-screen')),
      const Offset(0, 2000),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hero-story-play-button')),
      findsOneWidget,
    );
  });
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
