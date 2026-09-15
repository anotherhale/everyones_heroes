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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_owned_story_transcription_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_transcription_status_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_owned_story_transcription_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_transcription_status_request.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/capture/file_capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/local_file_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/transcription/file_story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/transcription/file_transcription_completion_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('hs11-durable-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test(
    'HS.11 durable path: capture → consent → start transcription → restart → transcript remains',
    () async {
      final eventBus = InMemoryEventBus(
        eventStore: InMemoryEventStore(),
        dispatcher: InMemoryEventDispatcher(),
      );

      final heroes1 = FileHeroRepository(rootDirectory: root);
      final stories1 = FileStoryRepository(rootDirectory: root);
      final media1 = LocalFileStoryMediaStorageAdapter(rootDirectory: root);
      final captureStore1 = FileCaptureCompletionStore(
        rootDirectory: root,
        storyRepository: stories1,
      );
      final txCompletion1 = FileTranscriptionCompletionStore(
        rootDirectory: root,
        storyRepository: stories1,
      );
      final jobs1 = FileStoryTranscriptionJobStore(rootDirectory: root);

      final createHero = CreateHeroUseCase(
        heroRepository: heroes1,
        eventBus: eventBus,
      );
      final heroId = HeroId.generate();
      expect(
        await createHero.execute(
          CreateHeroRequest(
            heroId: heroId,
            profile: HeroProfile(displayName: 'HS11 Hero'),
          ),
        ),
        isA<Success<Hero>>(),
      );

      final storyId = StoryId.generate();
      final audioId = StoryRepresentationId.generate();
      final capture = CompleteStoryCaptureUseCase(
        storyRepository: stories1,
        heroRepository: heroes1,
        mediaStorage: media1,
        eventBus: eventBus,
        completionStore: captureStore1,
      );
      expect(
        await capture.execute(
          CompleteStoryCaptureRequest(
            sessionId: 'session-${storyId.value}',
            heroId: heroId,
            storyId: storyId,
            representationId: audioId,
            originalLanguage: LanguageCode('en'),
            mediaBytes: Uint8List.fromList(List<int>.filled(96, 7)),
            contentType: 'audio/wav',
          ),
        ),
        isA<Success>(),
      );

      final consent = UpdateStoryConsentUseCase(
        storyRepository: stories1,
        eventBus: eventBus,
      );
      await consent.execute(
        UpdateStoryConsentRequest(
          storyId: storyId,
          grantProcessing: true,
          grantAiTransformation: true,
        ),
      );

      final start = StartOwnedStoryTranscriptionUseCase(
        storyRepository: stories1,
        heroRepository: heroes1,
        transcribeStory: TranscribeStoryRepresentationUseCase(
          storyRepository: stories1,
          mediaStorage: media1,
          transcriptionPort: InMemoryStoryTranscriptionAdapter(),
          eventBus: eventBus,
          completionStore: txCompletion1,
        ),
        jobStore: jobs1,
      );

      final started = await start.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: storyId,
          ownerHeroId: heroId,
        ),
      );
      expect(started, isA<Success>());

      // Simulate process restart with fresh repository/store instances.
      final stories2 = FileStoryRepository(rootDirectory: root);
      final media2 = LocalFileStoryMediaStorageAdapter(rootDirectory: root);
      final jobs2 = FileStoryTranscriptionJobStore(rootDirectory: root);
      final status = GetOwnedStoryTranscriptionStatusUseCase(
        storyRepository: stories2,
        heroRepository: FileHeroRepository(rootDirectory: root),
        jobStore: jobs2,
      );

      final statusResult = await status.execute(
        GetOwnedStoryTranscriptionStatusRequest(
          storyId: storyId,
          ownerHeroId: heroId,
        ),
      );
      expect(statusResult, isA<Success>());
      final value = (statusResult as Success).value;
      expect(value.status, StoryTranscriptionJobStatus.completed);
      expect(value.transcriptText, isNotEmpty);

      final story = await stories2.findById(storyId);
      expect(story, isNotNull);
      final audio = story!.findRepresentation(audioId)!;
      expect(audio.mediaReference, isNotNull);
      final bytes = await media2.retrieve(audio.mediaReference!);
      expect(bytes, isNotNull);
      expect(bytes!.length, 96);

      final transcripts = story.representations.where(
        (r) => r.format == StoryRepresentationFormat.transcript,
      );
      expect(transcripts.length, 1);
      expect(transcripts.first.sourceRepresentationId, audioId);
    },
  );
}
