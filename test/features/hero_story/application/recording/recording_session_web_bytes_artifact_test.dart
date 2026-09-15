import 'dart:async';
import 'dart:typed_data';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/complete_story_capture_response.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_service.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_state.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Models the web recording artifact path: bytes + synthetic memory:// marker,
/// with no dart:io filesystem usage.
final class _BytesOnlyDeviceRecordingAdapter implements DeviceRecordingPort {
  _BytesOnlyDeviceRecordingAdapter({
    this.permission = DevicePermissionStatus.granted,
    this.autoGrantOnRequest = true,
    Uint8List? audioBytes,
  }) : _audioBytes = audioBytes ?? Uint8List.fromList(List.filled(64, 7));

  DevicePermissionStatus permission;
  final bool autoGrantOnRequest;
  final Uint8List _audioBytes;
  final _failures = StreamController<DeviceRecordingFailureKind>.broadcast();
  bool _prepared = false;
  bool _recording = false;
  bool _paused = false;

  @override
  Stream<DeviceRecordingFailureKind> get failures => _failures.stream;

  @override
  Future<DevicePermissionStatus> checkMicrophonePermission() async =>
      permission;

  @override
  Future<DevicePermissionStatus> requestMicrophonePermission() async {
    if (permission == DevicePermissionStatus.permanentlyDenied ||
        permission == DevicePermissionStatus.unavailable) {
      return permission;
    }
    if (autoGrantOnRequest &&
        (permission == DevicePermissionStatus.notDetermined ||
            permission == DevicePermissionStatus.denied)) {
      permission = DevicePermissionStatus.granted;
    }
    return permission;
  }

  @override
  Future<void> prepare({RecordingMode mode = RecordingMode.audio}) async {
    if (mode == RecordingMode.video) {
      throw const DeviceRecordingException(
        'video unsupported',
        kind: DeviceRecordingFailureKind.cameraUnavailable,
      );
    }
    _prepared = true;
  }

  @override
  Future<void> start({RecordingMode mode = RecordingMode.audio}) async {
    if (!_prepared) {
      await prepare(mode: mode);
    }
    if (permission != DevicePermissionStatus.granted) {
      throw const DeviceRecordingException(
        'denied',
        kind: DeviceRecordingFailureKind.permissionDenied,
      );
    }
    _recording = true;
    _paused = false;
  }

  @override
  Future<void> pause() async {
    _paused = true;
  }

  @override
  Future<void> resume() async {
    _paused = false;
  }

  @override
  Future<LocalRecordingArtifact> stop() async {
    _recording = false;
    _paused = false;
    return LocalRecordingArtifact(
      localFilePath: 'memory://unit-test-recording.wav',
      duration: const Duration(seconds: 2),
      contentType: 'audio/wav',
      mode: RecordingMode.audio,
      byteLength: _audioBytes.length,
      bytes: Uint8List.fromList(_audioBytes),
    );
  }

  @override
  Future<void> cancel() async {
    _recording = false;
    _paused = false;
  }

  @override
  Future<bool> get isRecording async => _recording && !_paused;

  @override
  Future<bool> get isPaused async => _paused;

  @override
  Future<Duration> get elapsed async =>
      _recording ? const Duration(seconds: 2) : Duration.zero;

  Future<void> dispose() async => _failures.close();
}

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryStoryMediaStorageAdapter media;
  late InMemoryEventBus eventBus;
  late CompleteStoryCaptureUseCase completeCapture;
  late CreateHeroUseCase createHero;
  late _BytesOnlyDeviceRecordingAdapter recording;
  late RecordingSessionService session;

  final english = LanguageCode('en');

  setUp(() {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    media = InMemoryStoryMediaStorageAdapter();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    completeCapture = CompleteStoryCaptureUseCase(
      storyRepository: stories,
      heroRepository: heroes,
      mediaStorage: media,
      eventBus: eventBus,
    );
    createHero = CreateHeroUseCase(
      heroRepository: heroes,
      eventBus: eventBus,
    );
    recording = _BytesOnlyDeviceRecordingAdapter();
    session = RecordingSessionService(
      recordingPort: recording,
      completeCapture: completeCapture,
    );
  });

  tearDown(() async {
    await recording.dispose();
  });

  Future<HeroId> seedHero() async {
    final heroId = HeroId.generate();
    final result = await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Web Recorder'),
      ),
    );
    expect(result, isA<Success<Hero>>());
    return heroId;
  }

  test(
    'bytes artifact accept persists via mediaBytes without filesystem',
    () async {
      final heroId = await seedHero();
      await session.beginSession(heroId: heroId, originalLanguage: english);
      expect(await session.prepare(), DevicePermissionStatus.granted);
      expect(session.phase, RecordingSessionPhase.ready);

      await session.startRecording();
      await session.pauseRecording();
      await session.resumeRecording();
      final artifact = await session.stopRecording();

      expect(artifact.hasBytes, isTrue);
      expect(artifact.localFilePath, startsWith('memory://'));
      expect(session.phase, RecordingSessionPhase.reviewing);

      final accept = await session.accept();
      expect(accept, isA<Success<CompleteStoryCaptureResponse>>());
      expect(session.phase, RecordingSessionPhase.completed);
      expect(media.objectCount, 1);
    },
  );

  test('denied permission request keeps session preparing/failed', () async {
    await recording.dispose();
    recording = _BytesOnlyDeviceRecordingAdapter(
      permission: DevicePermissionStatus.denied,
      autoGrantOnRequest: false,
    );
    session = RecordingSessionService(
      recordingPort: recording,
      completeCapture: completeCapture,
    );

    final heroId = await seedHero();
    await session.beginSession(heroId: heroId, originalLanguage: english);
    await session.prepare();
    final status = await session.requestPermissions();
    expect(status, DevicePermissionStatus.denied);
    expect(session.phase, isNot(RecordingSessionPhase.ready));
  });
}
