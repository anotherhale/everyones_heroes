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
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/original_recording_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/fake_original_recording_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/just_audio_original_recording_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/hero_monogram.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/tell_your_story_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';
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
    tempDir = Directory.systemTemp.createTempSync('hs12-ui-');
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

  Future<void> captureThroughStorySaved(
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
  }

  test('monogram uses the hero name', () {
    expect(heroMonogram('Local Hero'), 'LH');
    expect(heroMonogram('Mary'), 'M');
    expect(heroMonogram('  Mary Ann Smith '), 'MS');
  });

  test('mime type follows the original bytes', () {
    final wav = Uint8List.fromList(<int>[
      0x52, 0x49, 0x46, 0x46, // RIFF
      0, 0, 0, 0,
      0x57, 0x41, 0x56, 0x45, // WAVE
    ]);
    expect(mimeTypeForOriginalRecordingBytes(wav), 'audio/wav');
    expect(
      mimeTypeForOriginalRecordingBytes(
        Uint8List.fromList('original-captured-recording'.codeUnits),
      ),
      'audio/mp4',
    );
  });

  testWidgets('Story Saved opens Hero Story with the persisted story', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughStorySaved(tester, container);

    expect(
      find.byKey(const ValueKey('capture-completed-title')),
      findsOneWidget,
    );
    expect(find.text('Hero Story'), findsOneWidget);
    expect(find.byType(OwnedStoryDetailScreen), findsNothing);

    await tester.tap(find.byKey(const ValueKey('capture-view-story-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hero-story-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('hero-story-name')), findsOneWidget);
    expect(find.text(heroName), findsOneWidget);
    expect(find.byKey(const ValueKey('hero-story-monogram')), findsOneWidget);
    expect(find.text('LH'), findsOneWidget);
    expect(find.byKey(const ValueKey('hero-story-title')), findsOneWidget);
    expect(find.text(storyTitle), findsOneWidget);
    expect(find.textContaining('Story —'), findsNothing);
    expect(find.text('Original recording'), findsOneWidget);
    expect(find.text('Play my recording'), findsOneWidget);
    expect(find.text('Understand my story'), findsOneWidget);

    final saved = await stories.findAll();
    expect(saved.single.title.value, storyTitle);

    await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.pumpAndSettle();

    expect(player.calls, containsAllInOrder(<String>['load', 'play']));
    expect(
      player.loadedBytes,
      Uint8List.fromList('original-captured-recording'.codeUnits),
    );
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.pumpAndSettle();
    expect(player.calls, contains('pause'));
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.pumpAndSettle();
    expect(player.calls.where((call) => call == 'play').length, 2);
    expect(find.text('Pause'), findsOneWidget);

    player.completePlayback();
    await tester.pumpAndSettle();
    expect(find.text('Play my recording'), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
    expect(
      container.read(heroStoryPlaybackProvider(saved.single.id.value)).phase,
      HeroStoryPlaybackPhase.completed,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hero-story-screen')), findsNothing);
    expect(
      find.byKey(const ValueKey('capture-completed-title')),
      findsOneWidget,
    );
    expect(find.text('Story Saved'), findsOneWidget);
  });

  testWidgets('failed original playback stays on Hero Story', (tester) async {
    player.failOnPlay = true;
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughStorySaved(tester, container);
    await tester.tap(find.byKey(const ValueKey('capture-view-story-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hero-story-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hero-story-playback-error')),
      findsOneWidget,
    );
    expect(
      find.text(HeroStoryPlaybackController.playbackError),
      findsOneWidget,
    );
    expect(find.textContaining('AI'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('capture-completed-title')),
      findsOneWidget,
    );
  });

  testWidgets('story details stays available from Hero Story', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughStorySaved(tester, container);
    await tester.tap(find.byKey(const ValueKey('capture-view-story-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hero-story-details-button')));
    await tester.pumpAndSettle();

    expect(find.byType(OwnedStoryDetailScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('owned-story-detail-app-bar')),
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
          child: const Text('Tell Your Story'),
        ),
      ),
    );
  }
}
