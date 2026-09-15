import 'dart:typed_data';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_transcription_status_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_owned_story_transcription_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_transcription_status_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_owned_story_transcription_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryStoryMediaStorageAdapter mediaStorage;
  late InMemoryEventBus eventBus;
  late InMemoryStoryTranscriptionJobStore jobStore;
  late InMemoryStoryTranscriptionAdapter transcriptionAdapter;
  late CreateHeroUseCase createHero;
  late CompleteStoryCaptureUseCase completeCapture;
  late UpdateStoryConsentUseCase updateConsent;
  late TranscribeStoryRepresentationUseCase transcribe;
  late StartOwnedStoryTranscriptionUseCase startOwned;
  late GetOwnedStoryTranscriptionStatusUseCase getStatus;

  final english = LanguageCode('en');

  setUp(() {
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    mediaStorage = InMemoryStoryMediaStorageAdapter();
    jobStore = InMemoryStoryTranscriptionJobStore();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    transcriptionAdapter = InMemoryStoryTranscriptionAdapter();
    createHero = CreateHeroUseCase(
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    completeCapture = CompleteStoryCaptureUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      mediaStorage: mediaStorage,
      eventBus: eventBus,
    );
    updateConsent = UpdateStoryConsentUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    transcribe = TranscribeStoryRepresentationUseCase(
      storyRepository: storyRepository,
      mediaStorage: mediaStorage,
      transcriptionPort: transcriptionAdapter,
      eventBus: eventBus,
    );
    startOwned = StartOwnedStoryTranscriptionUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      transcribeStory: transcribe,
      jobStore: jobStore,
    );
    getStatus = GetOwnedStoryTranscriptionStatusUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      jobStore: jobStore,
    );
  });

  Future<({HeroId heroId, StoryId storyId, StoryRepresentationId audioId})>
      seed({
    bool grantAi = true,
    bool grantProcessing = true,
    HeroId? owner,
  }) async {
    final heroId = owner ?? HeroId.generate();
    final storyId = StoryId.generate();
    final audioId = StoryRepresentationId.generate();

    if (await heroRepository.findById(heroId) == null) {
      final heroResult = await createHero.execute(
        CreateHeroRequest(
          heroId: heroId,
          profile: HeroProfile(displayName: 'Owner Hero'),
        ),
      );
      expect(heroResult, isA<Success<Hero>>());
    }

    final captureResult = await completeCapture.execute(
      CompleteStoryCaptureRequest(
        sessionId: 'session-${storyId.value}',
        heroId: heroId,
        storyId: storyId,
        representationId: audioId,
        originalLanguage: english,
        mediaBytes: Uint8List.fromList(List<int>.generate(64, (i) => i)),
        contentType: 'audio/wav',
      ),
    );
    expect(captureResult, isA<Success>());

    if (grantProcessing || grantAi) {
      await updateConsent.execute(
        UpdateStoryConsentRequest(
          storyId: storyId,
          grantProcessing: grantProcessing,
          grantAiTransformation: grantAi,
        ),
      );
    }

    return (heroId: heroId, storyId: storyId, audioId: audioId);
  }

  group('StartOwnedStoryTranscriptionUseCase', () {
    test('owner can start transcription and persist transcript', () async {
      final seeded = await seed();

      final result = await startOwned.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Success>());
      final response = (result as Success).value;
      expect(response.status, StoryTranscriptionJobStatus.completed);
      expect(response.transcriptText, isNotEmpty);

      final story = await storyRepository.findById(seeded.storyId);
      final transcripts = story!.representations.where(
        (r) => r.format == StoryRepresentationFormat.transcript,
      );
      expect(transcripts.length, 1);
      expect(transcripts.first.isAiGenerated, isTrue);
      expect(transcripts.first.sourceRepresentationId, seeded.audioId);
      expect(story.narrative.isProvisional, isTrue);

      final job = jobStore.find(
        storyId: seeded.storyId,
        sourceRepresentationId: seeded.audioId,
      );
      expect(job?.status, StoryTranscriptionJobStatus.completed);

      // Original recording remains.
      final audio = story.findRepresentation(seeded.audioId)!;
      expect(audio.mediaReference, isNotNull);
      final bytes = await mediaStorage.retrieve(audio.mediaReference!);
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
    });

    test('non-owner cannot start transcription', () async {
      final seeded = await seed();
      final other = HeroId.generate();
      await createHero.execute(
        CreateHeroRequest(
          heroId: other,
          profile: HeroProfile(displayName: 'Other'),
        ),
      );

      final result = await startOwned.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: other,
        ),
      );

      expect(result, isA<Failure>());
      expect((result as Failure).error, contains('not owned'));
    });

    test('consent is required', () async {
      final seeded = await seed(grantAi: false, grantProcessing: false);

      final result = await startOwned.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Failure>());
      expect((result as Failure).error.toLowerCase(), contains('consent'));
    });

    test('invokes HS.4 transcription port via use case', () async {
      final seeded = await seed();
      var calls = 0;
      final counting = _CountingTranscriptionAdapter(() => calls++);
      final localTranscribe = TranscribeStoryRepresentationUseCase(
        storyRepository: storyRepository,
        mediaStorage: mediaStorage,
        transcriptionPort: counting,
        eventBus: eventBus,
      );
      final localStart = StartOwnedStoryTranscriptionUseCase(
        storyRepository: storyRepository,
        heroRepository: heroRepository,
        transcribeStory: localTranscribe,
        jobStore: jobStore,
      );

      final result = await localStart.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Success>());
      expect(calls, 1);
    });

    test('failure is persisted and retry works', () async {
      final seeded = await seed();
      final failing = InMemoryStoryTranscriptionAdapter(
        forcedFailureMessage: 'provider boom',
      );
      final failingTranscribe = TranscribeStoryRepresentationUseCase(
        storyRepository: storyRepository,
        mediaStorage: mediaStorage,
        transcriptionPort: failing,
        eventBus: eventBus,
      );
      final failingStart = StartOwnedStoryTranscriptionUseCase(
        storyRepository: storyRepository,
        heroRepository: heroRepository,
        transcribeStory: failingTranscribe,
        jobStore: jobStore,
      );

      final failed = await failingStart.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(failed, isA<Failure>());
      final job = jobStore.find(
        storyId: seeded.storyId,
        sourceRepresentationId: seeded.audioId,
      );
      expect(job?.status, StoryTranscriptionJobStatus.failed);
      expect(job?.failureKind, isNotNull);

      final retryStart = StartOwnedStoryTranscriptionUseCase(
        storyRepository: storyRepository,
        heroRepository: heroRepository,
        transcribeStory: transcribe,
        jobStore: jobStore,
      );
      final retried = await retryStart.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
          isRetry: true,
        ),
      );
      expect(retried, isA<Success>());
      expect(
        (retried as Success).value.status,
        StoryTranscriptionJobStatus.completed,
      );
      final story = await storyRepository.findById(seeded.storyId);
      expect(
        story!.representations
            .where((r) => r.format == StoryRepresentationFormat.transcript)
            .length,
        1,
      );
    });

    test('duplicate start while completed returns idempotent replay', () async {
      final seeded = await seed();
      final first = await startOwned.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(first, isA<Success>());

      final second = await startOwned.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(second, isA<Success>());
      expect((second as Success).value.idempotentReplay, isTrue);
      final story = await storyRepository.findById(seeded.storyId);
      expect(
        story!.representations
            .where((r) => r.format == StoryRepresentationFormat.transcript)
            .length,
        1,
      );
    });

    test('duplicate start while in progress is prevented', () async {
      final seeded = await seed();
      jobStore.save(
        StoryTranscriptionJobTransitions.start(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.audioId,
          requestId: 'running',
          at: DateTime.utc(2026, 9, 15),
        ),
      );

      final result = await startOwned.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Failure>());
      expect((result as Failure).error.toLowerCase(), contains('in progress'));
    });
  });

  group('GetOwnedStoryTranscriptionStatusUseCase', () {
    test('reports notStarted then completed', () async {
      final seeded = await seed();
      final before = await getStatus.execute(
        GetOwnedStoryTranscriptionStatusRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(before, isA<Success>());
      expect(
        (before as Success).value.status,
        StoryTranscriptionJobStatus.notStarted,
      );
      expect(before.value.canStart, isTrue);

      await startOwned.execute(
        StartOwnedStoryTranscriptionRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      final after = await getStatus.execute(
        GetOwnedStoryTranscriptionStatusRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(after, isA<Success>());
      expect(
        (after as Success).value.status,
        StoryTranscriptionJobStatus.completed,
      );
      expect(after.value.transcriptText, isNotEmpty);
      expect(after.value.canStart, isFalse);
    });
  });
}

final class _CountingTranscriptionAdapter implements StoryTranscriptionPort {
  _CountingTranscriptionAdapter(this.onCall);

  final void Function() onCall;
  final InMemoryStoryTranscriptionAdapter _inner =
      InMemoryStoryTranscriptionAdapter();

  @override
  Future<StoryTranscriptionResult> transcribe(
    TranscribeStoryMediaRequest request,
  ) {
    onCall();
    return _inner.transcribe(request);
  }
}
