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
import 'package:everyonesheroes/features/hero_story/application/dto/responses/complete_story_capture_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/publish_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/submit_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryStoryMediaStorageAdapter mediaStorage;
  late InMemoryEventStore eventStore;
  late InMemoryEventBus eventBus;
  late CreateHeroUseCase createHero;
  late CompleteStoryCaptureUseCase completeCapture;
  late UpdateStoryConsentUseCase updateConsent;
  late SubmitStoryUseCase submitStory;
  late ApproveStoryUseCase approveStory;
  late PublishStoryUseCase publishStory;

  final english = LanguageCode('en');
  final spanish = LanguageCode('es');

  setUp(() {
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    mediaStorage = InMemoryStoryMediaStorageAdapter();
    eventStore = InMemoryEventStore();
    eventBus = InMemoryEventBus(
      eventStore: eventStore,
      dispatcher: InMemoryEventDispatcher(),
    );
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
    submitStory = SubmitStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    approveStory = ApproveStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    publishStory = PublishStoryUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
  });

  Future<HeroId> seedHero() async {
    final heroId = HeroId.generate();
    final result = await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Capture Hero'),
      ),
    );
    expect(result, isA<Success<Hero>>());
    return heroId;
  }

  CompleteStoryCaptureRequest requestFor({
    required HeroId heroId,
    required StoryId storyId,
    required StoryRepresentationId representationId,
    LanguageCode? language,
    String sessionId = 'session-1',
    List<int> bytes = const [1, 2, 3, 4, 5],
  }) {
    return CompleteStoryCaptureRequest(
      sessionId: sessionId,
      heroId: heroId,
      storyId: storyId,
      representationId: representationId,
      originalLanguage: language ?? english,
      mediaBytes: Uint8List.fromList(bytes),
      contentType: 'audio/mp4',
      duration: const Duration(minutes: 2),
    );
  }

  test('successful capture stores media and attaches original audio', () async {
    final heroId = await seedHero();
    final storyId = StoryId.generate();
    final representationId = StoryRepresentationId.generate();

    final result = await completeCapture.execute(
      requestFor(
        heroId: heroId,
        storyId: storyId,
        representationId: representationId,
      ),
    );

    expect(result, isA<Success<CompleteStoryCaptureResponse>>());
    final response = (result as Success<CompleteStoryCaptureResponse>).value;
    expect(response.createdStory, isTrue);
    expect(response.idempotentReplay, isFalse);
    expect(response.mediaReference.uri, startsWith('memory://'));

    final story = await storyRepository.findById(storyId);
    expect(story, isNotNull);
    expect(story!.hasProvisionalNarrative, isTrue);
    expect(story.visibility, StoryVisibility.private);
    expect(story.originalLanguage, english);
    expect(story.consent.isRecorded, isTrue);
    expect(story.consent.isProcessingApproved, isFalse);
    expect(story.representations, hasLength(1));
    expect(story.representations.single.format, StoryRepresentationFormat.audio);
    expect(story.representations.single.origin, RepresentationOrigin.original);
    expect(
      story.provenance.steps.single.transformationType,
      StoryTransformationType.recording,
    );

    final events = await eventStore.allEvents();
    expect(events.any((e) => e.event is StoryCreated), isTrue);
    expect(events.any((e) => e.event is StoryRepresentationAdded), isTrue);
  });

  test('consent gates for submit and publish remain independent', () async {
    final heroId = await seedHero();
    final storyId = StoryId.generate();
    await completeCapture.execute(
      requestFor(
        heroId: heroId,
        storyId: storyId,
        representationId: StoryRepresentationId.generate(),
      ),
    );

    final blockedSubmit = await submitStory.execute(
      StoryIdRequest(storyId: storyId),
    );
    expect(blockedSubmit, isA<Failure>());

    await updateConsent.execute(
      UpdateStoryConsentRequest(storyId: storyId, grantProcessing: true),
    );

    final story = (await storyRepository.findById(storyId))!;
    story.updateNarrative(
      narrative: StoryNarrative('Authored narrative after capture.'),
    );
    await storyRepository.save(story);

    final submitted = await submitStory.execute(
      StoryIdRequest(storyId: storyId),
    );
    expect(submitted, isA<Success>());

    await approveStory.execute(StoryIdRequest(storyId: storyId));

    final blockedPublish = await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.public,
      ),
    );
    expect(blockedPublish, isA<Failure>());

    await updateConsent.execute(
      UpdateStoryConsentRequest(storyId: storyId, grantPublication: true),
    );
    final published = await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.public,
      ),
    );
    expect(published, isA<Success>());
  });

  test('empty media and missing hero fail', () async {
    final empty = await completeCapture.execute(
      CompleteStoryCaptureRequest(
        sessionId: 'empty',
        heroId: HeroId.generate(),
        storyId: StoryId.generate(),
        representationId: StoryRepresentationId.generate(),
        originalLanguage: english,
        mediaBytes: Uint8List(0),
      ),
    );
    expect(empty, isA<Failure>());

    final missingHero = await completeCapture.execute(
      requestFor(
        heroId: HeroId.generate(),
        storyId: StoryId.generate(),
        representationId: StoryRepresentationId.generate(),
      ),
    );
    expect(missingHero, isA<Failure>());
  });

  test('duplicate session completion is idempotent', () async {
    final heroId = await seedHero();
    final storyId = StoryId.generate();
    final representationId = StoryRepresentationId.generate();
    final request = requestFor(
      heroId: heroId,
      storyId: storyId,
      representationId: representationId,
      sessionId: 'same-session',
    );

    final first = await completeCapture.execute(request);
    final second = await completeCapture.execute(request);
    expect(first, isA<Success>());
    expect(second, isA<Success>());
    expect(
      (second as Success<CompleteStoryCaptureResponse>).value.idempotentReplay,
      isTrue,
    );
    expect(mediaStorage.objectCount, 1);
    expect((await storyRepository.findById(storyId))!.representations, hasLength(1));
  });

  test('preserves non-English original language', () async {
    final heroId = await seedHero();
    final storyId = StoryId.generate();
    final result = await completeCapture.execute(
      requestFor(
        heroId: heroId,
        storyId: storyId,
        representationId: StoryRepresentationId.generate(),
        language: spanish,
      ),
    );
    expect(result, isA<Success>());
    final story = await storyRepository.findById(storyId);
    expect(story!.originalLanguage, spanish);
    expect(story.representations.single.language, spanish);
  });
}
