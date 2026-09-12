import 'dart:typed_data';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/apply_story_understanding_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_understanding_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/review_story_understanding_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/transcribe_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/apply_story_understanding_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_story_understanding_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/review_story_understanding_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_understanding_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_understanding_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/event_assertions.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryStoryUnderstandingRepository understandingRepository;
  late InMemoryStoryMediaStorageAdapter mediaStorage;
  late InMemoryEventStore eventStore;
  late InMemoryEventBus eventBus;
  late CreateHeroUseCase createHero;
  late CompleteStoryCaptureUseCase completeCapture;
  late UpdateStoryConsentUseCase updateConsent;
  late TranscribeStoryRepresentationUseCase transcribe;
  late GenerateStoryUnderstandingUseCase generateUnderstanding;
  late ReviewStoryUnderstandingUseCase reviewUnderstanding;
  late ApplyStoryUnderstandingUseCase applyUnderstanding;
  late InMemoryStoryTranscriptionAdapter transcriptionAdapter;
  late InMemoryStoryUnderstandingAdapter understandingAdapter;

  final english = LanguageCode('en');

  setUp(() {
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    understandingRepository = InMemoryStoryUnderstandingRepository();
    mediaStorage = InMemoryStoryMediaStorageAdapter();
    eventStore = InMemoryEventStore();
    eventBus = InMemoryEventBus(
      eventStore: eventStore,
      dispatcher: InMemoryEventDispatcher(),
    );
    transcriptionAdapter = InMemoryStoryTranscriptionAdapter();
    understandingAdapter = InMemoryStoryUnderstandingAdapter();
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
    generateUnderstanding = GenerateStoryUnderstandingUseCase(
      storyRepository: storyRepository,
      understandingRepository: understandingRepository,
      understandingPort: understandingAdapter,
      eventBus: eventBus,
    );
    reviewUnderstanding = ReviewStoryUnderstandingUseCase(
      understandingRepository: understandingRepository,
      eventBus: eventBus,
    );
    applyUnderstanding = ApplyStoryUnderstandingUseCase(
      storyRepository: storyRepository,
      understandingRepository: understandingRepository,
      eventBus: eventBus,
    );
  });

  Future<({HeroId heroId, StoryId storyId, StoryRepresentationId audioId})>
      seedCapturedStory({bool grantAi = true, bool grantProcessing = true}) async {
    final heroId = HeroId.generate();
    final storyId = StoryId.generate();
    final audioId = StoryRepresentationId.generate();

    final heroResult = await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Capture Hero'),
      ),
    );
    expect(heroResult, isA<Success<Hero>>());

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

  group('TranscribeStoryRepresentationUseCase', () {
    test('happy path attaches derived AI transcript representation', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = StoryRepresentationId.generate();
      final beforeEvents = (await eventStore.allEvents()).length;

      final result = await transcribe.execute(
        TranscribeStoryRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.audioId,
          requestId: 'tx-1',
          transcriptRepresentationId: transcriptId,
        ),
      );

      expect(result, isA<Success>());
      final response = (result as Success).value;
      expect(response.idempotentReplay, isFalse);
      expect(response.transcriptRepresentationId, transcriptId);

      final story = await storyRepository.findById(seeded.storyId);
      final transcript = story!.findRepresentation(transcriptId)!;
      expect(transcript.format, StoryRepresentationFormat.transcript);
      expect(transcript.origin, RepresentationOrigin.derived);
      expect(transcript.isAiGenerated, isTrue);
      expect(transcript.sourceRepresentationId, seeded.audioId);
      expect(transcript.textContent, isNotEmpty);
      expect(story.classification.isEmpty, isTrue);
      expect((await eventStore.allEvents()).length, greaterThan(beforeEvents));
      final newEvents = (await eventStore.allEvents())
          .skip(beforeEvents)
          .map((e) => e.event)
          .toList();
      expectEventRaised<StoryRepresentationAdded>(newEvents);
    });

    test('idempotent replay does not duplicate representation', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = StoryRepresentationId.generate();
      final request = TranscribeStoryRequest(
        storyId: seeded.storyId,
        sourceRepresentationId: seeded.audioId,
        requestId: 'tx-idem',
        transcriptRepresentationId: transcriptId,
      );

      final first = await transcribe.execute(request);
      final second = await transcribe.execute(request);

      expect(first, isA<Success>());
      expect(second, isA<Success>());
      expect((second as Success).value.idempotentReplay, isTrue);
      final story = await storyRepository.findById(seeded.storyId);
      expect(
        story!.representations.where((r) => r.id == transcriptId).length,
        1,
      );
    });

    test('requires AI and processing consent before port call', () async {
      final seeded = await seedCapturedStory(grantAi: false, grantProcessing: true);
      final result = await transcribe.execute(
        TranscribeStoryRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.audioId,
          requestId: 'tx-no-ai',
          transcriptRepresentationId: StoryRepresentationId.generate(),
        ),
      );
      expect(result, isA<Failure>());
      expect((result as Failure).error, contains('consent'));
    });

    test('revoked AI consent blocks transcription', () async {
      final seeded = await seedCapturedStory();
      await updateConsent.execute(
        UpdateStoryConsentRequest(
          storyId: seeded.storyId,
          revokeAiTransformation: true,
        ),
      );

      final result = await transcribe.execute(
        TranscribeStoryRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.audioId,
          requestId: 'tx-revoked',
          transcriptRepresentationId: StoryRepresentationId.generate(),
        ),
      );
      expect(result, isA<Failure>());
    });

    test('adapter failure leaves original audio and narrative intact', () async {
      final seeded = await seedCapturedStory();
      final failing = TranscribeStoryRepresentationUseCase(
        storyRepository: storyRepository,
        mediaStorage: mediaStorage,
        transcriptionPort: InMemoryStoryTranscriptionAdapter(
          forcedFailureMessage: 'timeout',
        ),
        eventBus: eventBus,
      );

      final storyBefore = await storyRepository.findById(seeded.storyId);
      final result = await failing.execute(
        TranscribeStoryRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.audioId,
          requestId: 'tx-fail',
          transcriptRepresentationId: StoryRepresentationId.generate(),
        ),
      );

      expect(result, isA<Failure>());
      final storyAfter = await storyRepository.findById(seeded.storyId);
      expect(storyAfter!.representations.length, storyBefore!.representations.length);
      expect(storyAfter.findRepresentation(seeded.audioId), isNotNull);
      expect(storyAfter.narrative, storyBefore.narrative);
    });

    test('missing source representation fails', () async {
      final seeded = await seedCapturedStory();
      final result = await transcribe.execute(
        TranscribeStoryRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: StoryRepresentationId.generate(),
          requestId: 'tx-missing',
          transcriptRepresentationId: StoryRepresentationId.generate(),
        ),
      );
      expect(result, isA<Failure>());
    });
  });

  group('GenerateStoryUnderstandingUseCase', () {
    Future<StoryRepresentationId> transcribeFor(StoryId storyId, StoryRepresentationId audioId) async {
      final transcriptId = StoryRepresentationId.generate();
      final result = await transcribe.execute(
        TranscribeStoryRequest(
          storyId: storyId,
          sourceRepresentationId: audioId,
          requestId: 'tx-for-${transcriptId.value}',
          transcriptRepresentationId: transcriptId,
        ),
      );
      expect(result, isA<Success>());
      return transcriptId;
    }

    test('generates proposed understanding without classifying Story', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = await transcribeFor(seeded.storyId, seeded.audioId);
      final understandingId = StoryUnderstandingId.generate();
      final classifiedBefore = (await eventStore.allEvents())
          .where((e) => e.event is StoryClassified)
          .length;

      final result = await generateUnderstanding.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-1',
          understandingId: understandingId,
        ),
      );

      expect(result, isA<Success>());
      final response = (result as Success).value;
      expect(response.understanding.status, UnderstandingStatus.proposed);
      expect(response.understanding.candidateClassification, isNotNull);

      final story = await storyRepository.findById(seeded.storyId);
      expect(story!.classification.isEmpty, isTrue);
      expect(
        (await eventStore.allEvents())
            .where((e) => e.event is StoryClassified)
            .length,
        classifiedBefore,
      );
      expect(
        (await eventStore.allEvents()).any(
          (e) => e.event is StoryUnderstandingProposed,
        ),
        isTrue,
      );
    });

    test('supersedes prior successful understanding', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = await transcribeFor(seeded.storyId, seeded.audioId);
      final firstId = StoryUnderstandingId.generate();
      final secondId = StoryUnderstandingId.generate();

      await generateUnderstanding.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-a',
          understandingId: firstId,
        ),
      );
      final second = await generateUnderstanding.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-b',
          understandingId: secondId,
        ),
      );

      expect(second, isA<Success>());
      final prior = await understandingRepository.findById(firstId);
      expect(prior!.status, UnderstandingStatus.superseded);
      expect(
        (second as Success).value.understanding.supersedesUnderstandingId,
        firstId,
      );
    });

    test('idempotent replay does not create duplicate understanding', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = await transcribeFor(seeded.storyId, seeded.audioId);
      final understandingId = StoryUnderstandingId.generate();
      final request = GenerateStoryUnderstandingRequest(
        storyId: seeded.storyId,
        sourceRepresentationIds: [transcriptId],
        requestId: 'und-idem',
        understandingId: understandingId,
      );

      final first = await generateUnderstanding.execute(request);
      final second = await generateUnderstanding.execute(request);
      expect(first, isA<Success>());
      expect((second as Success).value.idempotentReplay, isTrue);
      final all = await understandingRepository.findByStoryId(seeded.storyId);
      expect(all.where((u) => u.id == understandingId).length, 1);
    });

    test('consent required; revoked AI blocks generation', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = await transcribeFor(seeded.storyId, seeded.audioId);
      await updateConsent.execute(
        UpdateStoryConsentRequest(
          storyId: seeded.storyId,
          revokeAiTransformation: true,
        ),
      );

      final result = await generateUnderstanding.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-revoked',
          understandingId: StoryUnderstandingId.generate(),
        ),
      );
      expect(result, isA<Failure>());
    });

    test('adapter failure does not persist understanding or mutate Story', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = await transcribeFor(seeded.storyId, seeded.audioId);
      final failing = GenerateStoryUnderstandingUseCase(
        storyRepository: storyRepository,
        understandingRepository: understandingRepository,
        understandingPort: InMemoryStoryUnderstandingAdapter(
          forcedFailureMessage: 'unavailable',
        ),
        eventBus: eventBus,
      );

      final result = await failing.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-fail',
          understandingId: StoryUnderstandingId.generate(),
        ),
      );
      expect(result, isA<Failure>());
      expect(await understandingRepository.findLatestByStoryId(seeded.storyId), isNull);
      final story = await storyRepository.findById(seeded.storyId);
      expect(story!.classification.isEmpty, isTrue);
    });

    test('failed attempt does not supersede prior understanding', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = await transcribeFor(seeded.storyId, seeded.audioId);
      final firstId = StoryUnderstandingId.generate();
      await generateUnderstanding.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-ok',
          understandingId: firstId,
        ),
      );

      final failing = GenerateStoryUnderstandingUseCase(
        storyRepository: storyRepository,
        understandingRepository: understandingRepository,
        understandingPort: InMemoryStoryUnderstandingAdapter(
          forcedFailureMessage: 'boom',
        ),
        eventBus: eventBus,
      );
      await failing.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-boom',
          understandingId: StoryUnderstandingId.generate(),
        ),
      );

      final prior = await understandingRepository.findById(firstId);
      expect(prior!.status, UnderstandingStatus.proposed);
    });

    test('provider replacement still works via port injection', () async {
      final seeded = await seedCapturedStory();
      final transcriptId = await transcribeFor(seeded.storyId, seeded.audioId);
      final alternate = GenerateStoryUnderstandingUseCase(
        storyRepository: storyRepository,
        understandingRepository: understandingRepository,
        understandingPort: InMemoryStoryUnderstandingAdapter(
          injectUnknownSubjectLabel: 'resilience_trait',
        ),
        eventBus: eventBus,
      );

      final result = await alternate.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-alt',
          understandingId: StoryUnderstandingId.generate(),
        ),
      );
      expect(result, isA<Success>());
      final understanding = (result as Success).value.understanding;
      expect(
        understanding.observations.any((o) => o.kind == ObservationKind.uncertainty),
        isTrue,
      );
    });
  });

  group('Review and ApplyStoryUnderstandingUseCase', () {
    Future<StoryUnderstanding> generateReady() async {
      final seeded = await seedCapturedStory();
      final transcriptId = StoryRepresentationId.generate();
      await transcribe.execute(
        TranscribeStoryRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.audioId,
          requestId: 'tx-${transcriptId.value}',
          transcriptRepresentationId: transcriptId,
        ),
      );
      final understandingId = StoryUnderstandingId.generate();
      final generated = await generateUnderstanding.execute(
        GenerateStoryUnderstandingRequest(
          storyId: seeded.storyId,
          sourceRepresentationIds: [transcriptId],
          requestId: 'und-${understandingId.value}',
          understandingId: understandingId,
        ),
      );
      return (generated as Success).value.understanding;
    }

    test('review accept then apply classification via authoritative path', () async {
      final understanding = await generateReady();
      final reviewed = await reviewUnderstanding.execute(
        ReviewStoryUnderstandingRequest(
          understandingId: understanding.id,
          decision: UnderstandingReviewDecision.accept,
          reviewerActorId: 'reviewer-1',
        ),
      );
      expect(reviewed, isA<Success>());
      expect(
        (reviewed as Success).value.status,
        UnderstandingStatus.approved,
      );

      final beforeClassified = (await eventStore.allEvents())
          .where((e) => e.event is StoryClassified)
          .length;
      final applied = await applyUnderstanding.execute(
        ApplyStoryUnderstandingRequest(
          understandingId: understanding.id,
          applyClassification: true,
        ),
      );
      expect(applied, isA<Success>());
      final story = (applied as Success).value;
      expect(story.classification.isEmpty, isFalse);
      expect(
        (await eventStore.allEvents())
            .where((e) => e.event is StoryClassified)
            .length,
        beforeClassified + 1,
      );
    });

    test('review reject cannot be applied', () async {
      final understanding = await generateReady();
      await reviewUnderstanding.execute(
        ReviewStoryUnderstandingRequest(
          understandingId: understanding.id,
          decision: UnderstandingReviewDecision.reject,
        ),
      );

      final applied = await applyUnderstanding.execute(
        ApplyStoryUnderstandingRequest(
          understandingId: understanding.id,
          applyClassification: true,
        ),
      );
      expect(applied, isA<Failure>());
      final story = await storyRepository.findById(understanding.storyId);
      expect(story!.classification.isEmpty, isTrue);
    });

    test('partial review applies only accepted dimensions', () async {
      final understanding = await generateReady();
      await reviewUnderstanding.execute(
        ReviewStoryUnderstandingRequest(
          understandingId: understanding.id,
          decision: UnderstandingReviewDecision.partial,
          acceptClassification: true,
          acceptSuitability: false,
          acceptSpirituality: false,
        ),
      );

      final appliedClass = await applyUnderstanding.execute(
        ApplyStoryUnderstandingRequest(
          understandingId: understanding.id,
          applyClassification: true,
        ),
      );
      expect(appliedClass, isA<Success>());

      final appliedSuit = await applyUnderstanding.execute(
        ApplyStoryUnderstandingRequest(
          understandingId: understanding.id,
          applySuitability: true,
        ),
      );
      expect(appliedSuit, isA<Failure>());
    });

    test('review modify stores modified candidate snapshot', () async {
      final understanding = await generateReady();
      final modified = CandidateStoryClassification(
        subjects: [StorySubject.family, StorySubject.career],
      );
      final reviewed = await reviewUnderstanding.execute(
        ReviewStoryUnderstandingRequest(
          understandingId: understanding.id,
          decision: UnderstandingReviewDecision.modify,
          acceptClassification: true,
          acceptSuitability: true,
          acceptSpirituality: true,
          modifiedClassification: modified,
        ),
      );
      expect(reviewed, isA<Success>());
      expect(
        (reviewed as Success).value.effectiveClassification,
        modified,
      );
    });

    test('stale understanding blocked unless acknowledgeStale', () async {
      final understanding = await generateReady();
      await reviewUnderstanding.execute(
        ReviewStoryUnderstandingRequest(
          understandingId: understanding.id,
          decision: UnderstandingReviewDecision.accept,
        ),
      );

      // Remove source representation by creating a new story state without it:
      // replace story with same id but without representations via save of mutated copy.
      final story = await storyRepository.findById(understanding.storyId);
      // Simulate staleness by checking isStaleRelativeTo empty set path through apply:
      // Save a story that no longer has the transcript — rebuild without matching ids.
      final rebuilt = Story.createFromCapture(
        id: story!.id,
        heroId: story.heroId,
        originalLanguage: story.originalLanguage,
        createdAt: story.createdAt,
      );
      rebuilt.updateConsent(story.consent);
      await storyRepository.save(rebuilt);

      final blocked = await applyUnderstanding.execute(
        ApplyStoryUnderstandingRequest(
          understandingId: understanding.id,
          applyClassification: true,
        ),
      );
      expect(blocked, isA<Failure>());
      expect((blocked as Failure).error, contains('stale'));

      final forced = await applyUnderstanding.execute(
        ApplyStoryUnderstandingRequest(
          understandingId: understanding.id,
          applyClassification: true,
          acknowledgeStale: true,
        ),
      );
      expect(forced, isA<Success>());
    });

    test('apply suitability and spirituality when accepted', () async {
      final understanding = await generateReady();
      // Ensure candidates exist via modify if adapter omitted them.
      await reviewUnderstanding.execute(
        ReviewStoryUnderstandingRequest(
          understandingId: understanding.id,
          decision: UnderstandingReviewDecision.partial,
          acceptClassification: false,
          acceptSuitability: true,
          acceptSpirituality: true,
          modifiedSuitability: const CandidateContentSuitability(
            violence: SuitabilityLevel.mild,
          ),
          modifiedSpirituality: CandidateSpiritualityClassification(
            category: SpiritualityCategory.spiritual,
          ),
        ),
      );

      final suit = await applyUnderstanding.execute(
        ApplyStoryUnderstandingRequest(
          understandingId: understanding.id,
          applySuitability: true,
        ),
      );
      expect(suit, isA<Success>());
      expect(
        (suit as Success).value.contentSuitability.violence,
        SuitabilityLevel.mild,
      );

      final spirit = await applyUnderstanding.execute(
        ApplyStoryUnderstandingRequest(
          understandingId: understanding.id,
          applySpirituality: true,
        ),
      );
      expect(spirit, isA<Success>());
      expect(
        (spirit as Success).value.spirituality.category,
        SpiritualityCategory.spiritual,
      );
    });
  });
}
