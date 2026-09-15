import 'dart:io';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_state.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/tell_your_story_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_catalog_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/tell_your_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryStoryMediaStorageAdapter media;
  late InMemoryCaptureCompletionStore completionStore;
  late FakeDeviceRecordingAdapter recorder;
  late Directory tempDir;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    media = InMemoryStoryMediaStorageAdapter();
    completionStore = InMemoryCaptureCompletionStore();
    tempDir = Directory.systemTemp.createTempSync('hs9-ui-');
    recorder = FakeDeviceRecordingAdapter(
      outputDirectory: tempDir,
      initialPermission: DevicePermissionStatus.granted,
    );

    await heroes.save(
      hs.Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Local Hero',
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

  ProviderContainer buildContainer({
    DevicePermissionStatus? permission,
  }) {
    if (permission != null) {
      recorder.setPermissionStatus(permission);
    }
    final eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );

    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        storyMediaStoragePortProvider.overrideWithValue(media),
        captureCompletionStoreProvider.overrideWithValue(completionStore),
        eventBusProvider.overrideWithValue(eventBus),
        useRealDeviceRecordingProvider.overrideWithValue(false),
        deviceRecordingPortProvider.overrideWithValue(recorder),
        activeLocalHeroStoreProvider.overrideWithValue(ActiveLocalHeroStore()),
      ],
    );
  }

  Future<void> pumpTellYourStory(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TellYourStoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> waitForBootstrap(ProviderContainer container) async {
    for (var i = 0; i < 20; i++) {
      final phase = container.read(tellYourStoryControllerProvider).phase;
      if (phase != RecordingSessionPhase.idle) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  testWidgets('Heroes tab exposes Tell Your Story entry', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HeroCatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tell-your-story-button')), findsOneWidget);
  });

  testWidgets('permission denied shows recovery guidance', (tester) async {
    final container = buildContainer(
      permission: DevicePermissionStatus.permanentlyDenied,
    );
    addTearDown(container.dispose);

    await pumpTellYourStory(tester, container);
    await waitForBootstrap(container);
    await tester.pump();

    expect(find.byKey(const ValueKey('mic-permission-status')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('permission-settings-guidance')),
      findsOneWidget,
    );
  });

  testWidgets('prepare screen shows after bootstrap', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpTellYourStory(tester, container);
    await waitForBootstrap(container);
    await tester.pump();

    expect(find.byKey(const ValueKey('prepare-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-to-record-button')), findsOneWidget);
  });

  test('controller orchestrates capture through consent', () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final controller = container.read(tellYourStoryControllerProvider.notifier);

    await controller.startFlow();
    controller.continueToRecord();
    await controller.startRecording();
    await controller.pauseRecording();
    await controller.resumeRecording();
    await controller.stopRecording();
    await controller.acceptRecording();
    controller.setGrantProcessing(true);
    await controller.submitConsent();

    expect(container.read(tellYourStoryControllerProvider).step.name, 'completed');
    final owned = await stories.findAll();
    expect(owned, isNotEmpty);
    expect(owned.first.consent.isRecorded, isTrue);
    expect(owned.first.consent.isProcessingApproved, isTrue);
    expect(media.objectCount, greaterThan(0));
  });

  test('intentional Stop transitions to review without interruption banner',
      () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final controller = container.read(tellYourStoryControllerProvider.notifier);

    await controller.startFlow();
    controller.continueToRecord();
    await controller.startRecording();
    await controller.stopRecording();

    final ui = container.read(tellYourStoryControllerProvider);
    expect(ui.step, TellYourStoryStep.review);
    expect(ui.phase, RecordingSessionPhase.reviewing);
    expect(ui.errorMessage, isNull);
    // Duration is present for the review screen (may be zero in instant fakes).
    expect(ui.elapsed, isA<Duration>());
  });

  testWidgets(
    'intentional Stop review screen has controls and no error banner',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await pumpTellYourStory(tester, container);
      await tester.pump();
      // Allow bootstrap futures to complete outside fake-async.
      await tester.runAsync(() async {
        for (var i = 0; i < 40; i++) {
          final phase = container.read(tellYourStoryControllerProvider).phase;
          if (phase != RecordingSessionPhase.idle) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      });
      await tester.pump();

      final controller = container.read(tellYourStoryControllerProvider.notifier);

      await tester.runAsync(() async {
        controller.continueToRecord();
        await controller.startRecording();
        await controller.stopRecording();
      });
      await tester.pump();

      expect(find.byKey(const ValueKey('review-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-duration')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-play-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('accept-recording-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('retake-recording-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('discard-recording-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('tell-your-story-error')), findsNothing);
      expect(find.textContaining('Recording was interrupted'), findsNothing);

      await tester.runAsync(controller.discard);
      await tester.pump();
    },
  );

  test('genuine interruption while recording still shows interruption message',
      () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final controller = container.read(tellYourStoryControllerProvider.notifier);

    await controller.startFlow();
    controller.continueToRecord();
    await controller.startRecording();

    recorder.emitFailure(DeviceRecordingFailureKind.interrupted);
    await Future<void>.delayed(Duration.zero);

    final ui = container.read(tellYourStoryControllerProvider);
    expect(ui.step, TellYourStoryStep.record);
    expect(
      ui.errorMessage,
      'Recording was interrupted. You can review what was saved or retake.',
    );
  });

  test(
    'late interrupted signal after clean Stop does not reintroduce banner',
    () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final controller =
          container.read(tellYourStoryControllerProvider.notifier);

      await controller.startFlow();
      controller.continueToRecord();
      await controller.startRecording();
      await controller.stopRecording();

      expect(
        container.read(tellYourStoryControllerProvider).errorMessage,
        isNull,
      );

      // Simulates a late RecordState.stop failure event after intentional Stop.
      recorder.emitFailure(DeviceRecordingFailureKind.interrupted);
      await Future<void>.delayed(Duration.zero);

      final ui = container.read(tellYourStoryControllerProvider);
      expect(ui.step, TellYourStoryStep.review);
      expect(ui.phase, RecordingSessionPhase.reviewing);
      expect(ui.errorMessage, isNull);
    },
  );

  test('non-interruption device failures remain visible on review', () async {
    final container = buildContainer();
    addTearDown(container.dispose);
    final controller = container.read(tellYourStoryControllerProvider.notifier);

    await controller.startFlow();
    controller.continueToRecord();
    await controller.startRecording();
    await controller.stopRecording();

    recorder.emitFailure(DeviceRecordingFailureKind.storageInsufficient);
    await Future<void>.delayed(Duration.zero);

    final ui = container.read(tellYourStoryControllerProvider);
    expect(ui.step, TellYourStoryStep.review);
    expect(
      ui.errorMessage,
      'Not enough storage to continue recording.',
    );
  });
}
