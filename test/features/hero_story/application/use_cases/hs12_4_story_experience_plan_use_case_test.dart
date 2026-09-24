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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/understand_owned_hero_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_story_experience_plan_response.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_captured_story_reading_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_story_experience_plan_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_owned_story_transcription_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/understand_owned_hero_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_experience_planner_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_experience_plan_repository.dart';
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
  late InMemoryStoryExperiencePlannerAdapter plannerAdapter;
  late InMemoryStoryExperiencePlanRepository planRepository;
  late UnderstandOwnedHeroStoryUseCase understand;
  late GenerateStoryExperiencePlanUseCase generatePlan;
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
  });

  Future<({HeroId heroId, StoryId storyId})> seed() async {
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
        grantProcessing: true,
        grantAiTransformation: true,
      ),
    );
    return (heroId: heroId, storyId: storyId);
  }

  Future<void> seedWithReading(HeroId heroId, StoryId storyId) async {
    final result = await understand.execute(
      UnderstandOwnedHeroStoryRequest(
        storyId: storyId,
        ownerHeroId: heroId,
      ),
    );
    expect(result, isA<Success>());
  }

  test('fails clearly when Story is missing', () async {
    final result = await generatePlan.execute(
      GenerateStoryExperiencePlanAppRequest(storyId: StoryId('missing')),
    );
    expect(result, isA<Failure<GenerateStoryExperiencePlanResponse>>());
    expect(
      (result as Failure).error,
      contains('Story not found'),
    );
  });

  test('fails clearly when CapturedStoryReading is missing', () async {
    final seeded = await seed();
    final result = await generatePlan.execute(
      GenerateStoryExperiencePlanAppRequest(storyId: seeded.storyId),
    );
    expect(result, isA<Failure<GenerateStoryExperiencePlanResponse>>());
    expect(
      (result as Failure).error,
      contains('CapturedStoryReading not found'),
    );
  });

  test('planner is invoked with Story and reading; valid plan persisted',
      () async {
    final seeded = await seed();
    await seedWithReading(seeded.heroId, seeded.storyId);

    final beforeStory = await storyRepository.findById(seeded.storyId);
    final beforeReading =
        await readingRepository.findByStoryId(seeded.storyId);

    final result = await generatePlan.execute(
      GenerateStoryExperiencePlanAppRequest(storyId: seeded.storyId),
    );

    expect(result, isA<Success<GenerateStoryExperiencePlanResponse>>());
    final plan =
        (result as Success<GenerateStoryExperiencePlanResponse>).value.plan;
    expect(plan.storyId, seeded.storyId);
    expect(plan.keyMoments, isNotEmpty);
    expect(plan.sequence, isNotEmpty);

    final stored = await planRepository.findByStoryId(seeded.storyId);
    expect(stored?.id, plan.id);

    final afterStory = await storyRepository.findById(seeded.storyId);
    final afterReading =
        await readingRepository.findByStoryId(seeded.storyId);
    expect(afterStory, beforeStory);
    expect(afterReading, beforeReading);
  });

  test('planner failure is propagated', () async {
    final seeded = await seed();
    await seedWithReading(seeded.heroId, seeded.storyId);

    generatePlan = GenerateStoryExperiencePlanUseCase(
      storyRepository: storyRepository,
      readingRepository: readingRepository,
      planner: InMemoryStoryExperiencePlannerAdapter(
        forcedFailureMessage: 'planner exploded',
      ),
      planRepository: planRepository,
    );

    final result = await generatePlan.execute(
      GenerateStoryExperiencePlanAppRequest(storyId: seeded.storyId),
    );
    expect(result, isA<Failure<GenerateStoryExperiencePlanResponse>>());
    expect((result as Failure).error, contains('planner exploded'));
  });

  test('regenerated plan replaces existing plan without touching Story/reading',
      () async {
    final seeded = await seed();
    await seedWithReading(seeded.heroId, seeded.storyId);

    final first = await generatePlan.execute(
      GenerateStoryExperiencePlanAppRequest(storyId: seeded.storyId),
    );
    final firstPlan =
        (first as Success<GenerateStoryExperiencePlanResponse>).value.plan;

    final readingBefore =
        await readingRepository.findByStoryId(seeded.storyId);
    final storyBefore = await storyRepository.findById(seeded.storyId);

    final second = await generatePlan.execute(
      GenerateStoryExperiencePlanAppRequest(
        storyId: seeded.storyId,
        forceRegenerate: true,
        occurredAt: DateTime.utc(2026, 9, 25),
      ),
    );
    final secondPlan =
        (second as Success<GenerateStoryExperiencePlanResponse>).value.plan;

    expect(secondPlan.id, isNot(firstPlan.id));
    expect(await planRepository.findByStoryId(seeded.storyId), secondPlan);
    expect(await readingRepository.findByStoryId(seeded.storyId), readingBefore);
    expect(await storyRepository.findById(seeded.storyId), storyBefore);
  });
}
