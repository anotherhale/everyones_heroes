import 'dart:convert';
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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_experience_plan_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/run_experience_lab_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/understand_owned_hero_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/run_experience_lab_response.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_captured_story_reading_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_story_experience_plan_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/run_experience_lab_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_owned_story_transcription_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/understand_owned_hero_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/experience_lab_run_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/music_generation_port.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_creative_direction_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_music_generation_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_experience_planner_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_voice_rendering_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_experience_lab_run_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_experience_render_manifest_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_music_rendering_repository.dart';
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
  late InMemoryCreativeDirectionAdapter creativeAdapter;
  late InMemoryVoiceRenderingAdapter voiceAdapter;
  late InMemoryMusicGenerationAdapter musicAdapter;
  late InMemoryStoryVoiceRenderingRepository voiceRepository;
  late InMemoryMusicRenderingRepository musicRepository;
  late InMemoryExperienceLabRunRepository labRunRepository;
  late InMemoryExperienceRenderManifestRepository manifestRepository;
  late UnderstandOwnedHeroStoryUseCase understand;
  late GenerateStoryExperiencePlanUseCase generatePlan;
  late RunExperienceLabUseCase runLab;
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
    creativeAdapter = InMemoryCreativeDirectionAdapter();
    voiceAdapter = InMemoryVoiceRenderingAdapter(
      audioBytes: Uint8List.fromList(utf8.encode('narrated-audio-bytes')),
      contentType: 'audio/mpeg',
    );
    musicAdapter = InMemoryMusicGenerationAdapter(
      audioBytes: Uint8List.fromList(utf8.encode('music-audio-bytes')),
      contentType: 'audio/mpeg',
    );
    voiceRepository = InMemoryStoryVoiceRenderingRepository();
    musicRepository = InMemoryMusicRenderingRepository();
    labRunRepository = InMemoryExperienceLabRunRepository();
    manifestRepository = InMemoryExperienceRenderManifestRepository();
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
    runLab = RunExperienceLabUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      planRepository: planRepository,
      creativeDirectionPort: creativeAdapter,
      voiceRenderingPort: voiceAdapter,
      musicGenerationPort: musicAdapter,
      voiceRenderingRepository: voiceRepository,
      musicRenderingRepository: musicRepository,
      labRunRepository: labRunRepository,
      manifestRepository: manifestRepository,
      mediaStorage: mediaStorage,
    );
  });

  Future<({HeroId heroId, StoryId storyId})> seed({
    bool grantVoice = true,
    bool grantMusic = true,
    bool grantAi = true,
    bool grantProcessing = true,
  }) async {
    final heroId = HeroId.generate();
    final storyId = StoryId.generate();
    final audioId = StoryRepresentationId.generate();

    await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Lab Owner Hero'),
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
        grantMusicGeneration: grantMusic,
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

  group('RunExperienceLabUseCase', () {
    test('happy path generates creative + voice + music + manifest + lab run',
        () async {
      final seeded = await seed();
      await seedPlan(seeded.heroId, seeded.storyId);

      final beforeStory = await storyRepository.findById(seeded.storyId);
      final beforePlan = await planRepository.findByStoryId(seeded.storyId);
      final beforeReading =
          await readingRepository.findByStoryId(seeded.storyId);
      final beforeRepIds =
          beforeStory!.representations.map((r) => r.id.value).toList();

      final result = await runLab.execute(
        RunExperienceLabRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Success<RunExperienceLabResponse>>());
      final response = (result as Success<RunExperienceLabResponse>).value;
      expect(response.idempotentReplay, isFalse);
      expect(response.labRun.status, ExperienceLabRunStatus.succeeded);
      expect(response.labRun.isPlayable, isTrue);
      expect(response.manifest.musicRenderingId, isNotNull);
      expect(response.musicRendering.instrumental, isTrue);
      expect(response.voiceRendering, isNotNull);
      expect(creativeAdapter.callCount, 1);
      expect(voiceAdapter.callCount, 1);
      expect(musicAdapter.callCount, 1);
      expect(
        musicAdapter.lastRequest!.prompt.toLowerCase(),
        contains('instrumental'),
      );

      final afterStory = await storyRepository.findById(seeded.storyId);
      expect(
        afterStory!.representations.map((r) => r.id.value).toList(),
        beforeRepIds,
      );
      expect(afterStory.title.value, beforeStory.title.value);

      final afterPlan = await planRepository.findByStoryId(seeded.storyId);
      expect(afterPlan!.id, beforePlan!.id);
      expect(afterPlan.processingVersion, beforePlan.processingVersion);
      expect(afterPlan.coreMessage, beforePlan.coreMessage);

      final afterReading =
          await readingRepository.findByStoryId(seeded.storyId);
      expect(afterReading?.id, beforeReading?.id);
    });

    test('missing music consent fails', () async {
      final seeded = await seed(grantMusic: false);
      await seedPlan(seeded.heroId, seeded.storyId);

      final result = await runLab.execute(
        RunExperienceLabRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Failure<RunExperienceLabResponse>>());
      expect(
        (result as Failure).error.toLowerCase(),
        contains('music-generation'),
      );
      expect(creativeAdapter.callCount, 0);
      expect(musicAdapter.callCount, 0);
      expect(await labRunRepository.findByStoryId(seeded.storyId), isNull);
    });

    test('missing plan fails', () async {
      final seeded = await seed();
      // Consent granted, but no StoryExperiencePlan.

      final result = await runLab.execute(
        RunExperienceLabRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Failure<RunExperienceLabResponse>>());
      expect(
        (result as Failure).error,
        contains('StoryExperiencePlan not found'),
      );
      expect(creativeAdapter.callCount, 0);
    });

    test('creative direction failure surfaced — no silent fallback', () async {
      final seeded = await seed();
      await seedPlan(seeded.heroId, seeded.storyId);
      creativeAdapter.failWith = const CreativeDirectionException(
        'Creative direction proxy failed (502): provider down',
      );

      final result = await runLab.execute(
        RunExperienceLabRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Failure<RunExperienceLabResponse>>());
      expect(
        (result as Failure).error,
        allOf(contains('Creative direction failed'), contains('502')),
      );
      expect(voiceAdapter.callCount, 0);
      expect(musicAdapter.callCount, 0);
      final run = await labRunRepository.findByStoryId(seeded.storyId);
      expect(run!.status, ExperienceLabRunStatus.failed);
      expect(await musicRepository.findByStoryId(seeded.storyId), isNull);
    });

    test('music failure surfaced — no demo stem substitution', () async {
      final seeded = await seed();
      await seedPlan(seeded.heroId, seeded.storyId);
      musicAdapter.failWith = const MusicGenerationException(
        'Music generation proxy failed (503): model unavailable',
      );

      final result = await runLab.execute(
        RunExperienceLabRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Failure<RunExperienceLabResponse>>());
      expect(
        (result as Failure).error,
        allOf(contains('Music generation failed'), contains('503')),
      );
      expect(creativeAdapter.callCount, 1);
      expect(musicAdapter.callCount, 1);
      final run = await labRunRepository.findByStoryId(seeded.storyId);
      expect(run!.status, ExperienceLabRunStatus.partial);
      expect(await musicRepository.findByStoryId(seeded.storyId), isNull);
      expect(await manifestRepository.findByStoryId(seeded.storyId), isNull);
    });

    test('TTS failure surfaced', () async {
      final seeded = await seed();
      await seedPlan(seeded.heroId, seeded.storyId);
      voiceAdapter.failWith = const VoiceRenderingException(
        'Voice rendering proxy failed (502): TTS down',
      );

      final result = await runLab.execute(
        RunExperienceLabRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );

      expect(result, isA<Failure<RunExperienceLabResponse>>());
      expect((result as Failure).error, contains('TTS narration failed'));
      expect(musicAdapter.callCount, 0);
      final run = await labRunRepository.findByStoryId(seeded.storyId);
      expect(run!.status, ExperienceLabRunStatus.failed);
    });

    test('idempotent replay without regenerating when forceRegenerate=false',
        () async {
      final seeded = await seed();
      await seedPlan(seeded.heroId, seeded.storyId);

      final first = await runLab.execute(
        RunExperienceLabRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
        ),
      );
      expect(first, isA<Success<RunExperienceLabResponse>>());
      expect(creativeAdapter.callCount, 1);
      expect(voiceAdapter.callCount, 1);
      expect(musicAdapter.callCount, 1);
      final firstRun =
          (first as Success<RunExperienceLabResponse>).value.labRun;

      final second = await runLab.execute(
        RunExperienceLabRequest(
          storyId: seeded.storyId,
          ownerHeroId: seeded.heroId,
          forceRegenerate: false,
        ),
      );

      expect(second, isA<Success<RunExperienceLabResponse>>());
      final replay = (second as Success<RunExperienceLabResponse>).value;
      expect(replay.idempotentReplay, isTrue);
      expect(replay.labRun.id, firstRun.id);
      expect(creativeAdapter.callCount, 1);
      expect(voiceAdapter.callCount, 1);
      expect(musicAdapter.callCount, 1);
    });
  });
}
