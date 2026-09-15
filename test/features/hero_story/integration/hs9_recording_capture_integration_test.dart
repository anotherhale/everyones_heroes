import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_service.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_state.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_owned_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/capture/file_capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/local_file_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end HS.9 proof with durable local adapters + fake device recorder.
void main() {
  test(
    'Hero bootstrap → record → review → accept → durable Story + media survive reload',
    () async {
      final root = Directory.systemTemp.createTempSync('hs9-e2e-');
      final temp = Directory('${root.path}/temp')..createSync();
      addTearDown(() {
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      final heroes = FileHeroRepository(rootDirectory: root);
      final stories = FileStoryRepository(rootDirectory: root);
      final media = LocalFileStoryMediaStorageAdapter(rootDirectory: root);
      final completion = FileCaptureCompletionStore(
        rootDirectory: root,
        storyRepository: stories,
      );
      final eventBus = InMemoryEventBus(
        eventStore: InMemoryEventStore(),
        dispatcher: InMemoryEventDispatcher(),
      );

      final createHero = CreateHeroUseCase(
        heroRepository: heroes,
        eventBus: eventBus,
      );
      final heroResult = await createHero.execute(
        CreateHeroRequest(
          heroId: HeroId.generate(),
          profile: HeroProfile(
            displayName: 'Integration Hero',
            languages: [LanguageCode('en')],
          ),
          visibility: HeroVisibility.private,
        ),
      );
      expect(heroResult.isSuccess, isTrue);
      final hero = (heroResult as Success<Hero>).value;

      final recorder = FakeDeviceRecordingAdapter(
        outputDirectory: temp,
        initialPermission: DevicePermissionStatus.granted,
      );
      final complete = CompleteStoryCaptureUseCase(
        storyRepository: stories,
        heroRepository: heroes,
        mediaStorage: media,
        eventBus: eventBus,
        completionStore: completion,
      );
      final session = RecordingSessionService(
        recordingPort: recorder,
        completeCapture: complete,
        manifestDirectory: Directory('${root.path}/sessions')..createSync(),
      );

      await session.beginSession(
        heroId: hero.id,
        originalLanguage: LanguageCode('en'),
      );
      final sessionId = session.sessionId!;
      final storyId = session.storyId!;
      final representationId = session.representationId!;

      expect(await session.prepare(), DevicePermissionStatus.granted);
      await session.startRecording();
      await session.pauseRecording();
      await session.resumeRecording();
      final artifact = await session.stopRecording();
      expect(File(artifact.localFilePath).existsSync(), isTrue);
      expect(session.phase, RecordingSessionPhase.reviewing);

      final accept = await session.accept();
      expect(accept.isSuccess, isTrue);
      final response = (accept as Success).value;
      expect(response.story.consent.isRecorded, isTrue);
      expect(session.phase, RecordingSessionPhase.completed);

      // Simulate process restart with fresh repository instances on same root.
      final heroes2 = FileHeroRepository(rootDirectory: root);
      final stories2 = FileStoryRepository(rootDirectory: root);
      final media2 = LocalFileStoryMediaStorageAdapter(rootDirectory: root);
      final completion2 = FileCaptureCompletionStore(
        rootDirectory: root,
        storyRepository: stories2,
      );

      final reloadedHero = await heroes2.findById(hero.id);
      expect(reloadedHero, isNotNull);

      final owned = await ListHeroOwnedStoriesUseCase(
        storyRepository: stories2,
        heroRepository: heroes2,
      ).execute(ListHeroOwnedStoriesRequest(heroId: hero.id));
      expect(owned.isSuccess, isTrue);
      final ownedStories = (owned as Success).value;
      expect(ownedStories, isNotEmpty);
      expect(ownedStories.first.storyId, response.storyId);
      expect(ownedStories.first.isRecorded, isTrue);
      expect(ownedStories.first.hasMedia, isTrue);
      expect(ownedStories.first.primaryRepresentationId, isNotNull);

      final reloadedStory = await stories2.findById(response.storyId);
      expect(reloadedStory, isNotNull);
      expect(reloadedStory!.representations, isNotEmpty);
      final mediaRef = reloadedStory.representations.first.mediaReference!;
      expect(await media2.exists(mediaRef), isTrue);
      final bytes = await media2.retrieve(mediaRef);
      expect(bytes, isNotNull);
      expect(bytes!, isNotEmpty);

      final replay = await CompleteStoryCaptureUseCase(
        storyRepository: stories2,
        heroRepository: heroes2,
        mediaStorage: media2,
        eventBus: eventBus,
        completionStore: completion2,
      ).execute(
        CompleteStoryCaptureRequest(
          sessionId: sessionId,
          heroId: hero.id,
          storyId: storyId,
          representationId: representationId,
          originalLanguage: LanguageCode('en'),
          mediaBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      expect(replay.isSuccess, isTrue);
      expect((replay as Success).value.idempotentReplay, isTrue);

      // Silence unused StoryId import warning if analyzer is strict.
      expect(storyId, isA<StoryId>());
      expect(representationId, isA<StoryRepresentationId>());
    },
  );
}
