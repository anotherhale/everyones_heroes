import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_experience_plan_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/render_story_voice_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/understand_owned_hero_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/render_story_voice_response.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_captured_story_reading_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_story_experience_plan_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/render_story_voice_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_owned_story_transcription_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/understand_owned_hero_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_experience_planner_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_voice_rendering_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/voice_rendering_response_parser.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_voice_rendering_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_voice_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_voice_rendering_repository.dart';
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
  late InMemoryStoryExperiencePlannerAdapter plannerAdapter;
  late InMemoryStoryExperiencePlanRepository planRepository;
  late InMemoryVoiceRenderingAdapter voiceAdapter;
  late InMemoryStoryVoiceRenderingRepository voiceRepository;
  late UnderstandOwnedHeroStoryUseCase understand;
  late GenerateStoryExperiencePlanUseCase generatePlan;
  late RenderStoryVoiceUseCase renderVoice;
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
    plannerAdapter = InMemoryStoryExperiencePlannerAdapter();
    planRepository = InMemoryStoryExperiencePlanRepository();
    voiceAdapter = InMemoryVoiceRenderingAdapter(
      audioBytes: Uint8List.fromList(utf8.encode('narrated-audio-bytes')),
      contentType: 'audio/mpeg',
    );
    voiceRepository = InMemoryStoryVoiceRenderingRepository();
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
    generatePlan = GenerateStoryExperiencePlanUseCase(
      storyRepository: storyRepository,
      readingRepository: readingRepository,
      planner: plannerAdapter,
      planRepository: planRepository,
    );
    renderVoice = RenderStoryVoiceUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      planRepository: planRepository,
      voiceRenderingPort: voiceAdapter,
      renderingRepository: voiceRepository,
      mediaStorage: mediaStorage,
    );
  });

  Future<({HeroId heroId, StoryId storyId})> seed({
    bool grantVoice = false,
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
    await updateConsent.execute(
      UpdateStoryConsentRequest(
        storyId: storyId,
        grantProcessing: grantProcessing,
        grantAiTransformation: grantAi,
        grantVoiceRendering: grantVoice,
      ),
    );
    return (heroId: heroId, storyId: storyId);
  }

  Future<void> seedPlan(HeroId heroId, StoryId storyId) async {
    final understandResult = await understand.execute(
      UnderstandOwnedHeroStoryRequest(
        storyId: storyId,
        ownerHeroId: heroId,
      ),
    );
    expect(understandResult, isA<Success>());
    final planResult = await generatePlan.execute(
      GenerateStoryExperiencePlanAppRequest(storyId: storyId),
    );
    expect(planResult, isA<Success>());
  }

  group('consent', () {
    test('no voice-rendering consent blocks rendering', () async {
      final seeded = await seed(grantVoice: false);
      await seedPlan(seeded.heroId, seeded.storyId);

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Failure<RenderStoryVoiceResponse>>());
      expect(
        (result as Failure).error,
        contains('voice-rendering authorization'),
      );
      expect(voiceAdapter.callCount, 0);
      expect(await voiceRepository.findByStoryId(seeded.storyId), isNull);
    });

    test('explicit voice-rendering consent allows rendering', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Success<RenderStoryVoiceResponse>>());
      expect(voiceAdapter.callCount, 1);
    });

    test('recording consent alone is insufficient', () async {
      final seeded = await seed(
        grantVoice: false,
        grantAi: false,
        grantProcessing: false,
      );
      // Story is recorded via completeCapture; no AI/voice/processing.
      final story = await storyRepository.findById(seeded.storyId);
      expect(story!.consent.isRecorded, isTrue);
      expect(story.consent.isVoiceRenderingApproved, isFalse);

      final originalAudio = story.representations.firstWhere(
        (r) => r.format == StoryRepresentationFormat.audio,
      );
      final transcriptId = StoryRepresentationId.generate();
      story.addRepresentation(
        StoryRepresentation(
          id: transcriptId,
          language: english,
          format: StoryRepresentationFormat.transcript,
          origin: RepresentationOrigin.derived,
          textContent: 'Keep going through the challenge.',
          sourceRepresentationId: originalAudio.id,
          isAiGenerated: true,
          isApproved: false,
        ),
      );
      await storyRepository.save(story);

      final plan = StoryExperiencePlan(
        id: StoryExperiencePlanId.generate(),
        storyId: seeded.storyId,
        transcriptRepresentationId: transcriptId,
        intention: StoryExperienceIntention.inspire,
        coreMessage: 'Keep going.',
        emotionalArc: StoryExperienceArc.challenge,
        keyMoments: [
          StoryExperienceMoment(
            id: 'm1',
            description: 'A step.',
            sourceSpan: SourceSpanReference(
              representationId: transcriptId,
              startOffset: 0,
              endOffset: 4,
            ),
          ),
        ],
        musicDirection: StoryExperienceMusicDirection(
          mood: 'hopeful',
          energy: 'low',
          style: 'ambient',
          rationale: 'Support the opening.',
        ),
        reflectionPrompt: 'What moved you?',
        sequence: const [
          StoryExperienceStep(type: StoryExperienceStepType.story),
          StoryExperienceStep(
            type: StoryExperienceStepType.keyMoment,
            referenceId: 'm1',
          ),
        ],
        createdAt: DateTime.utc(2026, 9, 24),
      );
      await planRepository.save(plan);

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(result, isA<Failure<RenderStoryVoiceResponse>>());
      expect((result as Failure).error, contains('voice-rendering'));
      expect(voiceAdapter.callCount, 0);
    });

    test('transcription / AI consent alone is insufficient', () async {
      final seeded = await seed(grantVoice: false, grantAi: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      final story = await storyRepository.findById(seeded.storyId);
      expect(story!.consent.isAiTransformationApproved, isTrue);
      expect(story.consent.isVoiceRenderingApproved, isFalse);

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(result, isA<Failure<RenderStoryVoiceResponse>>());
      expect(voiceAdapter.callCount, 0);
    });
  });

  group('rendering', () {
    test('valid proxy response produces a derived artifact', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      final beforeStory = await storyRepository.findById(seeded.storyId);
      final beforePlan = await planRepository.findByStoryId(seeded.storyId);

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Success<RenderStoryVoiceResponse>>());
      final rendering =
          (result as Success<RenderStoryVoiceResponse>).value.rendering;
      expect(rendering.storyId, seeded.storyId);
      expect(rendering.experiencePlanId, beforePlan!.id);
      expect(
        rendering.experiencePlanProcessingVersion,
        beforePlan.processingVersion,
      );
      expect(
        rendering.sourceRepresentationId,
        beforePlan.transcriptRepresentationId,
      );
      expect(rendering.renderingMode, VoiceRenderingMode.syntheticNarration);
      expect(rendering.isAiGenerated, isTrue);
      expect(rendering.byteLength, greaterThan(0));

      final afterStory = await storyRepository.findById(seeded.storyId);
      expect(afterStory!.representations.length, beforeStory!.representations.length);
      expect(afterStory.title.value, beforeStory.title.value);
    });

    test('malformed response rejected', () {
      expect(
        () => VoiceRenderingResponseParser.parse('{not-json'),
        throwsA(isA<VoiceRenderingException>()),
      );
      expect(
        () => VoiceRenderingResponseParser.parse('{"audioBase64":"!!!"}'),
        throwsA(isA<VoiceRenderingException>()),
      );
    });

    test('empty audio rejected', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      voiceAdapter.audioBytes = Uint8List(0);

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(result, isA<Failure<RenderStoryVoiceResponse>>());
      expect((result as Failure).error.toLowerCase(), contains('empty'));
      expect(await voiceRepository.findByStoryId(seeded.storyId), isNull);
    });

    test('provider failure handled', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      voiceAdapter.failWith = const VoiceRenderingException(
        'Voice rendering proxy failed (502): provider down',
      );

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(result, isA<Failure<RenderStoryVoiceResponse>>());
      expect((result as Failure).error, contains('502'));
      expect(await voiceRepository.findByStoryId(seeded.storyId), isNull);
    });

    test('timeout handled', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      voiceAdapter.failWith = const VoiceRenderingException(
        'Voice rendering timed out: TimeoutException',
      );

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(result, isA<Failure<RenderStoryVoiceResponse>>());
      expect((result as Failure).error.toLowerCase(), contains('timed out'));
    });

    test('authentication failure handled', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      voiceAdapter.failWith = const VoiceRenderingException(
        'Voice rendering authentication failed.',
      );

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(result, isA<Failure<RenderStoryVoiceResponse>>());
      expect(
        (result as Failure).error.toLowerCase(),
        contains('authentication'),
      );
    });

    test('unexpected content type rejected', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      voiceAdapter.contentType = 'text/plain';

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(result, isA<Failure<RenderStoryVoiceResponse>>());
      expect(
        (result as Failure).error.toLowerCase(),
        contains('content type'),
      );
      expect(await voiceRepository.findByStoryId(seeded.storyId), isNull);
    });
  });

  group('provenance', () {
    test('generated artifact retains required source/provenance', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      final plan = await planRepository.findByStoryId(seeded.storyId);

      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      final rendering =
          (result as Success<RenderStoryVoiceResponse>).value.rendering;

      expect(rendering.experiencePlanId, plan!.id);
      expect(
        rendering.experiencePlanProcessingVersion,
        plan.processingVersion,
      );
      expect(
        rendering.sourceRepresentationId,
        plan.transcriptRepresentationId,
      );
      expect(rendering.providerLabel, isNotNull);
      expect(rendering.processingVersion, StoryVoiceRendering.defaultProcessingVersion);
      expect(voiceAdapter.lastRequest!.sourceText, isNotEmpty);
    });

    test('artifact does not mutate Story', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      final before = await storyRepository.findById(seeded.storyId);
      final beforeJson = before!.representations.map((r) => r.id.value).toList();

      await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      final after = await storyRepository.findById(seeded.storyId);
      expect(after!.representations.map((r) => r.id.value).toList(), beforeJson);
      expect(after.consent.isVoiceRenderingApproved, isTrue);
    });
  });

  group('persistence', () {
    test('generated artifact survives reload/restart', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      final result = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      final rendering =
          (result as Success<RenderStoryVoiceResponse>).value.rendering;

      final temp = Directory.systemTemp.createTempSync('hs12-6-voice-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final fileRepo = FileStoryVoiceRenderingRepository(rootDirectory: temp);
      await fileRepo.save(rendering);

      final reloaded = FileStoryVoiceRenderingRepository(rootDirectory: temp);
      final loaded = await reloaded.findByStoryId(seeded.storyId);
      expect(loaded, isNotNull);
      expect(loaded!.id, rendering.id);
      expect(loaded.mediaReference.uri, rendering.mediaReference.uri);
      expect(loaded.experiencePlanId, rendering.experiencePlanId);

      final roundTrip = StoryVoiceRenderingSnapshotMapper.fromJson(
        StoryVoiceRenderingSnapshotMapper.toJson(rendering),
      );
      expect(roundTrip, rendering);
    });

    test('invalid artifact is not persisted', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      voiceAdapter.audioBytes = Uint8List(0);

      await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(await voiceRepository.findByStoryId(seeded.storyId), isNull);
    });

    test('existing artifact can be loaded without regenerating', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      final first = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(voiceAdapter.callCount, 1);
      final firstId =
          (first as Success<RenderStoryVoiceResponse>).value.rendering.id;

      final second = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(voiceAdapter.callCount, 1);
      expect(
        (second as Success<RenderStoryVoiceResponse>).value.idempotentReplay,
        isTrue,
      );
      expect(second.value.rendering.id, firstId);
    });

    test('regeneration creates a new artifact id', () async {
      final seeded = await seed(grantVoice: true);
      await seedPlan(seeded.heroId, seeded.storyId);
      final first = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      final firstId =
          (first as Success<RenderStoryVoiceResponse>).value.rendering.id;

      final second = await renderVoice.execute(
        RenderStoryVoiceAppRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
          forceRegenerate: true,
        ),
      );
      expect(voiceAdapter.callCount, 2);
      final secondId =
          (second as Success<RenderStoryVoiceResponse>).value.rendering.id;
      expect(secondId, isNot(firstId));
      expect(
        (await voiceRepository.findByStoryId(seeded.storyId))!.id,
        secondId,
      );
    });
  });
}
