import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
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
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late Directory manifestDir;
  late FakeDeviceRecordingAdapter recording;
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryStoryMediaStorageAdapter mediaStorage;
  late InMemoryEventBus eventBus;
  late CompleteStoryCaptureUseCase completeCapture;
  late RecordingSessionService session;
  late CreateHeroUseCase createHero;

  final english = LanguageCode('en');
  var tick = DateTime.utc(2026, 9, 14, 8);
  var sessionSeq = 0;

  DateTime clock() => tick;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rec-session-');
    manifestDir = await Directory.systemTemp.createTemp('rec-manifest-');
    tick = DateTime.utc(2026, 9, 14, 8);
    sessionSeq = 0;

    recording = FakeDeviceRecordingAdapter(
      outputDirectory: tempDir,
      clock: clock,
    );
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    mediaStorage = InMemoryStoryMediaStorageAdapter();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    completeCapture = CompleteStoryCaptureUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      mediaStorage: mediaStorage,
      eventBus: eventBus,
    );
    createHero = CreateHeroUseCase(
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    session = RecordingSessionService(
      recordingPort: recording,
      completeCapture: completeCapture,
      manifestDirectory: manifestDir,
      sessionIdFactory: () {
        sessionSeq += 1;
        return 'session-$sessionSeq';
      },
    );
  });

  tearDown(() async {
    await recording.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    if (await manifestDir.exists()) {
      await manifestDir.delete(recursive: true);
    }
  });

  Future<HeroId> seedHero() async {
    final heroId = HeroId.generate();
    final result = await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Recorder'),
      ),
    );
    expect(result, isA<Success<Hero>>());
    return heroId;
  }

  Future<void> prepareReady(HeroId heroId) async {
    await session.beginSession(heroId: heroId, originalLanguage: english);
    final status = await session.prepare();
    expect(status, DevicePermissionStatus.granted);
    expect(session.phase, RecordingSessionPhase.ready);
  }

  test('full start/pause/resume/stop/accept deletes temp and completes', () async {
    final heroId = await seedHero();
    await prepareReady(heroId);

    await session.startRecording();
    expect(session.phase, RecordingSessionPhase.recording);
    tick = tick.add(const Duration(seconds: 2));
    await session.pauseRecording();
    expect(session.phase, RecordingSessionPhase.paused);
    tick = tick.add(const Duration(seconds: 5));
    await session.resumeRecording();
    tick = tick.add(const Duration(seconds: 3));

    final artifact = await session.stopRecording();
    expect(session.phase, RecordingSessionPhase.reviewing);
    expect(artifact.duration, const Duration(seconds: 5));
    expect(await File(artifact.localFilePath).exists(), isTrue);

    final accept = await session.accept();
    expect(accept, isA<Success<CompleteStoryCaptureResponse>>());
    expect(session.phase, RecordingSessionPhase.completed);
    expect(await File(artifact.localFilePath).exists(), isFalse);
    expect(mediaStorage.objectCount, 1);

    final response = (accept as Success<CompleteStoryCaptureResponse>).value;
    final saved = await storyRepository.findById(response.storyId);
    expect(saved, isNotNull);
    expect(saved!.consent.isRecorded, isTrue);
    expect(saved.representations, hasLength(1));
    expect(saved.representations.single.format, StoryRepresentationFormat.audio);
  });

  test('retake mints new sessionId and returns to ready', () async {
    final heroId = await seedHero();
    await prepareReady(heroId);
    final firstSession = session.sessionId;
    final firstRep = session.representationId;

    await session.startRecording();
    tick = tick.add(const Duration(seconds: 1));
    final artifact = await session.stopRecording();
    final tempPath = artifact.localFilePath;

    await session.retake();
    expect(session.phase, RecordingSessionPhase.ready);
    expect(session.sessionId, isNot(firstSession));
    expect(session.representationId, isNot(firstRep));
    expect(session.artifact, isNull);
    expect(await File(tempPath).exists(), isFalse);
  });

  test('discard cancels temp and clears session to idle', () async {
    final heroId = await seedHero();
    await prepareReady(heroId);
    await session.startRecording();
    tick = tick.add(const Duration(seconds: 1));
    final artifact = await session.stopRecording();

    await session.discard();
    expect(session.phase, RecordingSessionPhase.idle);
    expect(session.sessionId, isNull);
    expect(await File(artifact.localFilePath).exists(), isFalse);
    expect(mediaStorage.objectCount, 0);
  });

  test('accept storage failure stays reviewing and keeps temp for retry', () async {
    final heroId = await seedHero();
    final failingStorage = _FailOnceMediaStorage(mediaStorage);
    final failingComplete = CompleteStoryCaptureUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      mediaStorage: failingStorage,
      eventBus: eventBus,
    );
    session = RecordingSessionService(
      recordingPort: recording,
      completeCapture: failingComplete,
      manifestDirectory: manifestDir,
      sessionIdFactory: () {
        sessionSeq += 1;
        return 'session-$sessionSeq';
      },
    );

    await prepareReady(heroId);
    await session.startRecording();
    tick = tick.add(const Duration(seconds: 1));
    final artifact = await session.stopRecording();

    final first = await session.accept();
    expect(first, isA<Failure>());
    expect(session.phase, RecordingSessionPhase.reviewing);
    expect(await File(artifact.localFilePath).exists(), isTrue);

    final second = await session.accept();
    expect(second, isA<Success<CompleteStoryCaptureResponse>>());
    expect(session.phase, RecordingSessionPhase.completed);
    expect(await File(artifact.localFilePath).exists(), isFalse);
  });

  test('writes session manifest JSON under directory', () async {
    final heroId = await seedHero();
    await prepareReady(heroId);
    final manifestFile = File('${manifestDir.path}/${session.sessionId}.json');
    expect(await manifestFile.exists(), isTrue);
    final body = await manifestFile.readAsString();
    expect(body, contains('"phase":"ready"'));
    expect(body, contains(heroId.value));
  });
}

final class _FailOnceMediaStorage implements StoryMediaStoragePort {
  _FailOnceMediaStorage(this._inner);

  final InMemoryStoryMediaStorageAdapter _inner;
  var _failedOnce = false;

  @override
  Future<MediaReference> store(StoreStoryMediaRequest request) =>
      _inner.store(request);

  @override
  Future<MediaReference> storeFromFile(
    StoreStoryMediaFromFileRequest request,
  ) async {
    if (!_failedOnce) {
      _failedOnce = true;
      throw const StoryMediaStorageException('Simulated storage failure.');
    }
    return _inner.storeFromFile(request);
  }

  @override
  Future<bool> exists(MediaReference reference) => _inner.exists(reference);

  @override
  Future<Uint8List?> retrieve(MediaReference reference) =>
      _inner.retrieve(reference);

  @override
  Future<void> delete(MediaReference reference) => _inner.delete(reference);
}
