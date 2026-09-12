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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_unapproved_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/transcribe_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/translate_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_narrative_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_unapproved_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_story_script_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/translate_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_narrative_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_authoring_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_translation_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryStoryMediaStorageAdapter mediaStorage;
  late InMemoryEventStore eventStore;
  late InMemoryEventBus eventBus;
  late CreateHeroUseCase createHero;
  late CompleteStoryCaptureUseCase completeCapture;
  late UpdateStoryConsentUseCase updateConsent;
  late TranscribeStoryRepresentationUseCase transcribe;
  late GenerateStoryScriptUseCase generateScript;
  late ApproveStoryRepresentationUseCase approveRepresentation;
  late EditUnapprovedStoryRepresentationUseCase editRepresentation;
  late UpdateStoryNarrativeUseCase updateNarrative;
  late TranslateStoryRepresentationUseCase translateRepresentation;

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
    transcribe = TranscribeStoryRepresentationUseCase(
      storyRepository: storyRepository,
      mediaStorage: mediaStorage,
      transcriptionPort: InMemoryStoryTranscriptionAdapter(),
      eventBus: eventBus,
    );
    generateScript = GenerateStoryScriptUseCase(
      storyRepository: storyRepository,
      authoringPort: InMemoryStoryAuthoringAdapter(),
      eventBus: eventBus,
    );
    approveRepresentation = ApproveStoryRepresentationUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    editRepresentation = EditUnapprovedStoryRepresentationUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    updateNarrative = UpdateStoryNarrativeUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    translateRepresentation = TranslateStoryRepresentationUseCase(
      storyRepository: storyRepository,
      translationPort: InMemoryStoryTranslationAdapter(),
      eventBus: eventBus,
    );
  });

  Future<
      ({
        StoryId storyId,
        StoryRepresentationId audioId,
        StoryRepresentationId transcriptId,
      })> seedTranscribedStory({
    bool grantAi = true,
    bool grantProcessing = true,
  }) async {
    final heroId = HeroId.generate();
    final storyId = StoryId.generate();
    final audioId = StoryRepresentationId.generate();
    final transcriptId = StoryRepresentationId.generate();

    final heroResult = await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Authoring Hero'),
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

    final transcriptResult = await transcribe.execute(
      TranscribeStoryRequest(
        storyId: storyId,
        sourceRepresentationId: audioId,
        requestId: 'tx-${storyId.value}',
        transcriptRepresentationId: transcriptId,
      ),
    );
    expect(transcriptResult, isA<Success>());

    return (
      storyId: storyId,
      audioId: audioId,
      transcriptId: transcriptId,
    );
  }

  group('GenerateStoryScriptUseCase', () {
    test('creates unapproved script and preserves narrative', () async {
      final seeded = await seedTranscribedStory();
      final scriptId = StoryRepresentationId.generate();
      final narrativeBefore =
          (await storyRepository.findById(seeded.storyId))!.narrative.value;
      final beforeEvents = (await eventStore.allEvents()).length;

      final result = await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: scriptId,
          requestId: 'auth-1',
        ),
      );

      expect(result, isA<Success>());
      final story = await storyRepository.findById(seeded.storyId);
      final script = story!.findRepresentation(scriptId)!;
      expect(script.format, StoryRepresentationFormat.script);
      expect(script.origin, RepresentationOrigin.derived);
      expect(script.isAiGenerated, isTrue);
      expect(script.isApproved, isFalse);
      expect(script.isAuthoritative, isFalse);
      expect(script.sourceRepresentationId, seeded.transcriptId);
      expect(story.narrative.value, narrativeBefore);
      expect(
        story.provenance.steps.any(
          (s) =>
              s.transformationType == StoryTransformationType.scriptGeneration,
        ),
        isTrue,
      );

      final newEvents = (await eventStore.allEvents())
          .skip(beforeEvents)
          .map((e) => e.event)
          .toList();
      expectEventRaised<StoryRepresentationAdded>(newEvents);
    });

    test('requires AI consent', () async {
      final seeded = await seedTranscribedStory();
      await updateConsent.execute(
        UpdateStoryConsentRequest(
          storyId: seeded.storyId,
          revokeAiTransformation: true,
        ),
      );
      final result = await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: StoryRepresentationId.generate(),
          requestId: 'auth-denied',
        ),
      );
      expect(result, isA<Failure>());
    });

    test('idempotent replay does not duplicate representation', () async {
      final seeded = await seedTranscribedStory();
      final scriptId = StoryRepresentationId.generate();
      final request = GenerateStoryScriptRequest(
        storyId: seeded.storyId,
        sourceRepresentationId: seeded.transcriptId,
        authoredRepresentationId: scriptId,
        requestId: 'auth-idem',
      );

      final first = await generateScript.execute(request);
      final second = await generateScript.execute(request);
      expect(first, isA<Success>());
      expect(second, isA<Success>());
      expect((second as Success).value.idempotentReplay, isTrue);
      final story = await storyRepository.findById(seeded.storyId);
      expect(
        story!.representations.where((r) => r.id == scriptId).length,
        1,
      );
    });

    test('shortForm uses the same authoring seam', () async {
      final seeded = await seedTranscribedStory();
      final shortId = StoryRepresentationId.generate();
      final narrativeBefore =
          (await storyRepository.findById(seeded.storyId))!.narrative.value;

      final result = await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: shortId,
          requestId: 'auth-short',
          targetFormat: StoryRepresentationFormat.shortForm,
        ),
      );

      expect(result, isA<Success>());
      final story = await storyRepository.findById(seeded.storyId);
      expect(
        story!.findRepresentation(shortId)!.format,
        StoryRepresentationFormat.shortForm,
      );
      expect(story.narrative.value, narrativeBefore);
    });
  });

  group('ApproveStoryRepresentationUseCase', () {
    test('approves script and raises StoryRepresentationApproved', () async {
      final seeded = await seedTranscribedStory();
      final scriptId = StoryRepresentationId.generate();
      await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: scriptId,
          requestId: 'auth-approve-src',
        ),
      );
      final narrativeBefore =
          (await storyRepository.findById(seeded.storyId))!.narrative.value;
      final beforeEvents = (await eventStore.allEvents()).length;

      final result = await approveRepresentation.execute(
        ApproveStoryRepresentationRequest(
          storyId: seeded.storyId,
          representationId: scriptId,
          requestId: 'approve-1',
        ),
      );

      expect(result, isA<Success>());
      final story = await storyRepository.findById(seeded.storyId);
      expect(story!.findRepresentation(scriptId)!.isApproved, isTrue);
      expect(story.findRepresentation(scriptId)!.isAuthoritative, isTrue);
      expect(story.narrative.value, narrativeBefore);

      final newEvents = (await eventStore.allEvents())
          .skip(beforeEvents)
          .map((e) => e.event)
          .toList();
      expectEventRaised<StoryRepresentationApproved>(newEvents);
    });

    test('already approved is idempotent without new event', () async {
      final seeded = await seedTranscribedStory();
      final scriptId = StoryRepresentationId.generate();
      await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: scriptId,
          requestId: 'auth-approve-2',
        ),
      );
      await approveRepresentation.execute(
        ApproveStoryRepresentationRequest(
          storyId: seeded.storyId,
          representationId: scriptId,
        ),
      );

      final beforeEvents = (await eventStore.allEvents()).length;
      final second = await approveRepresentation.execute(
        ApproveStoryRepresentationRequest(
          storyId: seeded.storyId,
          representationId: scriptId,
          requestId: 'approve-2',
        ),
      );
      expect(second, isA<Success>());
      expect((second as Success).value.idempotentReplay, isTrue);
      final newEvents = (await eventStore.allEvents())
          .skip(beforeEvents)
          .map((e) => e.event)
          .toList();
      expectNoEventRaised<StoryRepresentationApproved>(newEvents);
    });
  });

  group('EditUnapprovedStoryRepresentationUseCase', () {
    test('updates unapproved text without mutating narrative', () async {
      final seeded = await seedTranscribedStory();
      final scriptId = StoryRepresentationId.generate();
      await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: scriptId,
          requestId: 'auth-edit-1',
        ),
      );
      final narrativeBefore =
          (await storyRepository.findById(seeded.storyId))!.narrative.value;

      final result = await editRepresentation.execute(
        EditUnapprovedStoryRepresentationRequest(
          storyId: seeded.storyId,
          representationId: scriptId,
          textContent: 'Hero-edited script draft',
        ),
      );

      expect(result, isA<Success>());
      final story = await storyRepository.findById(seeded.storyId);
      expect(story!.findRepresentation(scriptId)!.textContent,
          'Hero-edited script draft');
      expect(story.narrative.value, narrativeBefore);
      expect(
        story.provenance.steps.any(
          (s) => s.transformationType == StoryTransformationType.editing,
        ),
        isTrue,
      );
    });

    test('rejects edit of approved representation', () async {
      final seeded = await seedTranscribedStory();
      final scriptId = StoryRepresentationId.generate();
      await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: scriptId,
          requestId: 'auth-edit-2',
        ),
      );
      await approveRepresentation.execute(
        ApproveStoryRepresentationRequest(
          storyId: seeded.storyId,
          representationId: scriptId,
        ),
      );

      final result = await editRepresentation.execute(
        EditUnapprovedStoryRepresentationRequest(
          storyId: seeded.storyId,
          representationId: scriptId,
          textContent: 'Should fail',
        ),
      );
      expect(result, isA<Failure>());
    });
  });

  group('UpdateStoryNarrativeUseCase', () {
    test('human narrative update works without AI consent', () async {
      final seeded = await seedTranscribedStory();
      await updateConsent.execute(
        UpdateStoryConsentRequest(
          storyId: seeded.storyId,
          revokeAiTransformation: true,
        ),
      );
      final result = await updateNarrative.execute(
        UpdateStoryNarrativeRequest(
          storyId: seeded.storyId,
          title: StoryTitle('Authored Title'),
          narrative: StoryNarrative('Hero authored canonical narrative.'),
        ),
      );
      expect(result, isA<Success>());
      final story = await storyRepository.findById(seeded.storyId);
      expect(story!.narrative.value, 'Hero authored canonical narrative.');
      expect(story.narrative.isProvisional, isFalse);
    });
  });

  group('TranslateStoryRepresentationUseCase', () {
    test('creates unapproved translation without mutating original language',
        () async {
      final seeded = await seedTranscribedStory();
      final scriptId = StoryRepresentationId.generate();
      await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: scriptId,
          requestId: 'auth-tr-src',
        ),
      );

      final translatedId = StoryRepresentationId.generate();
      final before = (await storyRepository.findById(seeded.storyId))!;
      final narrativeBefore = before.narrative.value;
      final originalLanguageBefore = before.originalLanguage;

      final result = await translateRepresentation.execute(
        TranslateStoryRepresentationRequestDto(
          storyId: seeded.storyId,
          sourceRepresentationId: scriptId,
          translatedRepresentationId: translatedId,
          targetLanguage: spanish,
          requestId: 'tr-1',
        ),
      );

      expect(result, isA<Success>());
      final story = await storyRepository.findById(seeded.storyId);
      final translated = story!.findRepresentation(translatedId)!;
      expect(translated.origin, RepresentationOrigin.translated);
      expect(translated.language, spanish);
      expect(translated.isApproved, isFalse);
      expect(translated.sourceRepresentationId, scriptId);
      expect(story.narrative.value, narrativeBefore);
      expect(story.originalLanguage, originalLanguageBefore);
    });
  });

  group('HS.5 vertical slice', () {
    test('generate → edit → approve keeps canonical narrative unchanged',
        () async {
      final seeded = await seedTranscribedStory();
      final scriptId = StoryRepresentationId.generate();
      final narrativeBefore =
          (await storyRepository.findById(seeded.storyId))!.narrative.value;

      await generateScript.execute(
        GenerateStoryScriptRequest(
          storyId: seeded.storyId,
          sourceRepresentationId: seeded.transcriptId,
          authoredRepresentationId: scriptId,
          requestId: 'slice-1',
        ),
      );
      await editRepresentation.execute(
        EditUnapprovedStoryRepresentationRequest(
          storyId: seeded.storyId,
          representationId: scriptId,
          textContent: 'Reviewed script text',
        ),
      );
      final approve = await approveRepresentation.execute(
        ApproveStoryRepresentationRequest(
          storyId: seeded.storyId,
          representationId: scriptId,
          requestId: 'slice-approve',
        ),
      );

      expect(approve, isA<Success>());
      final story = await storyRepository.findById(seeded.storyId);
      expect(story!.narrative.value, narrativeBefore);
      expect(story.findRepresentation(scriptId)!.isAuthoritative, isTrue);
      expect(
        story.findRepresentation(scriptId)!.textContent,
        'Reviewed script text',
      );
    });
  });
}
