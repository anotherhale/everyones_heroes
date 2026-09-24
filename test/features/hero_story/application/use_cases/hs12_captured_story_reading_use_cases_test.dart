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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/understand_owned_hero_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/understand_owned_hero_story_response.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_captured_story_reading_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_owned_story_transcription_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/understand_owned_hero_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_captured_story_reading_repository.dart';
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
  late InMemoryCapturedStoryReadingAdapter readingAdapter;
  late InMemoryCapturedStoryReadingRepository readingRepository;
  late UnderstandOwnedHeroStoryUseCase understand;
  late CreateHeroUseCase createHero;
  late CompleteStoryCaptureUseCase completeCapture;
  late UpdateStoryConsentUseCase updateConsent;

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
    readingAdapter = InMemoryCapturedStoryReadingAdapter();
    readingRepository = InMemoryCapturedStoryReadingRepository();
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
    final transcribe = TranscribeStoryRepresentationUseCase(
      storyRepository: storyRepository,
      mediaStorage: mediaStorage,
      transcriptionPort: transcriptionAdapter,
      eventBus: eventBus,
    );
    final startOwned = StartOwnedStoryTranscriptionUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      transcribeStory: transcribe,
      jobStore: jobStore,
    );
    final generateReading = GenerateCapturedStoryReadingUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      readingPort: readingAdapter,
      readingRepository: readingRepository,
    );
    understand = UnderstandOwnedHeroStoryUseCase(
      startTranscription: startOwned,
      generateReading: generateReading,
    );
  });

  Future<({HeroId heroId, StoryId storyId, StoryRepresentationId audioId})>
      seed({
    bool grantAi = true,
    bool grantProcessing = true,
  }) async {
    final heroId = HeroId.generate();
    final storyId = StoryId.generate();
    final audioId = StoryRepresentationId.generate();

    await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Owner Hero'),
      ),
    );
    await completeCapture.execute(
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

  test('understand transcribes original audio and returns grounded reading',
      () async {
    final seeded = await seed();
    final before = await storyRepository.findById(seeded.storyId);

    final result = await understand.execute(
      UnderstandOwnedHeroStoryRequest(
        storyId: seeded.storyId,
        ownerHeroId: seeded.heroId,
      ),
    );

    expect(result, isA<Success<UnderstandOwnedHeroStoryResponse>>());
    final response =
        (result as Success<UnderstandOwnedHeroStoryResponse>).value;
    expect(response.transcriptText, isNotEmpty);
    expect(response.reading.movement.text, isNotEmpty);
    expect(response.reading.themes, isNotEmpty);
    expect(response.reading.challenge.sourceSpan.startOffset, isNotNull);
    expect(response.reading.turningPoint.sourceSpan.endOffset, isNotNull);
    expect(response.reading.outcome.text, isNotEmpty);
    response.reading.assertSpansWithinTranscript(response.transcriptText);

    final after = await storyRepository.findById(seeded.storyId);
    expect(after!.title.value, before!.title.value);
    expect(after.heroId, before.heroId);
    // Transcript representation may be added; narrative/classification unchanged.
    expect(after.lifecycleStatus, before.lifecycleStatus);
    expect(after.visibility, before.visibility);

    final stored = await readingRepository.findByStoryId(seeded.storyId);
    expect(stored?.id, response.reading.id);
  });

  test('understand fails without AI consent and leaves story unchanged',
      () async {
    final seeded = await seed(grantAi: false, grantProcessing: true);
    final before = await storyRepository.findById(seeded.storyId);
    final repCount = before!.representations.length;

    final result = await understand.execute(
      UnderstandOwnedHeroStoryRequest(
        storyId: seeded.storyId,
        ownerHeroId: seeded.heroId,
      ),
    );

    expect(result, isA<Failure>());
    final after = await storyRepository.findById(seeded.storyId);
    expect(after!.representations.length, repCount);
    expect(await readingRepository.findByStoryId(seeded.storyId), isNull);
  });

  test('reading failure still leaves original recording on the story', () async {
    readingAdapter = InMemoryCapturedStoryReadingAdapter(
      forcedFailureMessage: 'reading boom',
    );
    final generateReading = GenerateCapturedStoryReadingUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      readingPort: readingAdapter,
      readingRepository: readingRepository,
    );
    final startOwned = StartOwnedStoryTranscriptionUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      transcribeStory: TranscribeStoryRepresentationUseCase(
        storyRepository: storyRepository,
        mediaStorage: mediaStorage,
        transcriptionPort: transcriptionAdapter,
        eventBus: eventBus,
      ),
      jobStore: jobStore,
    );
    understand = UnderstandOwnedHeroStoryUseCase(
      startTranscription: startOwned,
      generateReading: generateReading,
    );

    final seeded = await seed();
    final result = await understand.execute(
      UnderstandOwnedHeroStoryRequest(
        storyId: seeded.storyId,
        ownerHeroId: seeded.heroId,
      ),
    );

    expect(result, isA<Failure>());
    final story = await storyRepository.findById(seeded.storyId);
    final hasOriginalAudio = story!.representations.any(
      (r) =>
          r.origin == RepresentationOrigin.original &&
          r.format == StoryRepresentationFormat.audio,
    );
    expect(hasOriginalAudio, isTrue);
  });

  test('failed reading can be retried after adapter recovers', () async {
    final failing = _ToggleReadingAdapter();
    final generateReading = GenerateCapturedStoryReadingUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      readingPort: failing,
      readingRepository: readingRepository,
    );
    final startOwned = StartOwnedStoryTranscriptionUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      transcribeStory: TranscribeStoryRepresentationUseCase(
        storyRepository: storyRepository,
        mediaStorage: mediaStorage,
        transcriptionPort: transcriptionAdapter,
        eventBus: eventBus,
      ),
      jobStore: jobStore,
    );
    understand = UnderstandOwnedHeroStoryUseCase(
      startTranscription: startOwned,
      generateReading: generateReading,
    );

    final seeded = await seed();
    final first = await understand.execute(
      UnderstandOwnedHeroStoryRequest(
        storyId: seeded.storyId,
        ownerHeroId: seeded.heroId,
      ),
    );
    expect(first, isA<Failure>());

    failing.fail = false;
    final second = await understand.execute(
      UnderstandOwnedHeroStoryRequest(
        storyId: seeded.storyId,
        ownerHeroId: seeded.heroId,
        isRetry: true,
      ),
    );
    expect(second, isA<Success>());
  });
}

final class _ToggleReadingAdapter implements CapturedStoryReadingPort {
  bool fail = true;
  final InMemoryCapturedStoryReadingAdapter _ok =
      InMemoryCapturedStoryReadingAdapter();

  @override
  Future<CapturedStoryReadingDraft> generate(
    GenerateCapturedStoryReadingRequest request,
  ) {
    if (fail) {
      throw const CapturedStoryReadingException('temporary failure');
    }
    return _ok.generate(request);
  }
}
