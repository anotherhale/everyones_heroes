import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_service.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_state.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/unavailable_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves the HS.9 session error strings observed on web when the unavailable
/// adapter is bound — matching Tell Your Story runtime behavior.
void main() {
  late UnavailableDeviceRecordingAdapter recording;
  late RecordingSessionService session;

  setUp(() {
    recording = UnavailableDeviceRecordingAdapter();
    final eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    session = RecordingSessionService(
      recordingPort: recording,
      completeCapture: CompleteStoryCaptureUseCase(
        storyRepository: InMemoryStoryRepository(),
        heroRepository: InMemoryHeroRepository(),
        mediaStorage: InMemoryStoryMediaStorageAdapter(),
        eventBus: eventBus,
      ),
    );
  });

  tearDown(() async {
    await recording.dispose();
  });

  test(
    'prepare with unavailable adapter fails before any browser mic call',
    () async {
      await session.beginSession(
        heroId: HeroId.generate(),
        originalLanguage: LanguageCode('en'),
      );

      final status = await session.prepare();
      expect(status, DevicePermissionStatus.unavailable);
      expect(session.phase, RecordingSessionPhase.failed);
      expect(session.lastError, 'Microphone is unavailable on this device.');
    },
  );

  test(
    'requestPermissions maps unavailable to permission-not-granted error',
    () async {
      await session.beginSession(
        heroId: HeroId.generate(),
        originalLanguage: LanguageCode('en'),
      );
      await session.prepare();

      final status = await session.requestPermissions();
      expect(status, DevicePermissionStatus.unavailable);
      expect(session.phase, RecordingSessionPhase.failed);
      expect(session.lastError, 'Microphone permission was not granted.');
    },
  );

  test(
    'startRecording is blocked by session phase before MediaRecorder',
    () async {
      await session.beginSession(
        heroId: HeroId.generate(),
        originalLanguage: LanguageCode('en'),
      );
      await session.prepare();

      await expectLater(
        session.startRecording(),
        throwsA(isA<StateError>()),
      );
    },
  );
}
