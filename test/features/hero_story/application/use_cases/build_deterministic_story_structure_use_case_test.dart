import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/advance_story_builder_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/build_deterministic_story_structure_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_builder_response_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_builder_session_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/abandon_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/build_deterministic_story_structure_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_story_builder_response_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/skip_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStoryBuilderSessionRepository repository;
  late EventBus eventBus;
  late StartStoryBuilderSessionUseCase start;
  late AdvanceStoryBuilderUseCase advance;
  late AnswerStoryBuilderPromptUseCase answer;
  late SkipStoryBuilderPromptUseCase skip;
  late EditStoryBuilderResponseUseCase edit;
  late AbandonStoryBuilderSessionUseCase abandon;
  late BuildDeterministicStoryStructureUseCase buildStructure;

  setUp(() {
    repository = InMemoryStoryBuilderSessionRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    const strategy = DeterministicStoryBuilderQuestionStrategy();
    start = StartStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    advance = AdvanceStoryBuilderUseCase(
      sessionRepository: repository,
      questionStrategy: strategy,
      eventBus: eventBus,
    );
    answer = AnswerStoryBuilderPromptUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    skip = SkipStoryBuilderPromptUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    edit = EditStoryBuilderResponseUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    abandon = AbandonStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    buildStructure = BuildDeterministicStoryStructureUseCase(
      sessionRepository: repository,
    );
  });

  Future<StoryBuilderSessionId> startSession() async {
    final id = StoryBuilderSessionId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: id,
        heroId: HeroId.generate(),
        mode: StoryBuilderMode.guided,
      ),
    );
    return id;
  }

  Future<AdvanceStoryBuilderResult> advanceOnce(StoryBuilderSessionId id) async {
    final result = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: id),
    );
    return (result as Success<AdvanceStoryBuilderResult>).value;
  }

  test('builds structure for empty in-progress session', () async {
    final id = await startSession();
    final result = await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(sessionId: id),
    );

    expect(result, isA<Success<DeterministicStoryStructure>>());
    final structure =
        (result as Success<DeterministicStoryStructure>).value;
    expect(structure.sessionId, id);
    expect(structure.sectionCount, 11);
    expect(structure.emptySectionCount, 11);
    expect(structure.populatedSectionCount, 0);
  });

  test('builds structure for completed session with provenance', () async {
    final id = await startSession();
    final responseIds = <StoryBuilderResponseId>[];

    for (var i = 0; i < 11; i++) {
      final step = await advanceOnce(id);
      final responseId = StoryBuilderResponseId.generate();
      responseIds.add(responseId);
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: id,
          responseId: responseId,
          promptId: step.currentPrompt!.id,
          text: 'Hero words for step $i',
        ),
      );
    }
    final done = await advanceOnce(id);
    expect(done.session.status, StoryBuilderSessionStatus.completed);
    expect(done.session.storyId, isNull);

    final result = await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(sessionId: id),
    );
    final structure =
        (result as Success<DeterministicStoryStructure>).value;

    expect(structure.populatedSectionCount, 11);
    for (var i = 0; i < 11; i++) {
      expect(structure.sections[i].sourceResponseIds, [responseIds[i]]);
      expect(structure.sections[i].hasSourceMaterial, isTrue);
    }
  });

  test('edit keeps response id reference across rebuilds', () async {
    final id = await startSession();
    final step = await advanceOnce(id);
    final challengeResponseId = StoryBuilderResponseId.generate();

    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        responseId: challengeResponseId,
        promptId: step.currentPrompt!.id,
        text: 'Original beginning.',
      ),
    );

    var structure = (await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(sessionId: id),
    ) as Success<DeterministicStoryStructure>)
        .value;
    expect(
      structure.sectionForRole(StoryBuilderNarrativeRole.beginning)!
          .sourceResponseIds,
      [challengeResponseId],
    );

    await edit.execute(
      EditStoryBuilderResponseRequest(
        sessionId: id,
        responseId: challengeResponseId,
        text: 'Edited beginning — still the same response id.',
      ),
    );

    structure = (await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(sessionId: id),
    ) as Success<DeterministicStoryStructure>)
        .value;
    expect(
      structure.sectionForRole(StoryBuilderNarrativeRole.beginning)!
          .sourceResponseIds,
      [challengeResponseId],
    );

    final session = await repository.findById(id);
    expect(
      session!.responses.firstWhere((r) => r.id == challengeResponseId).text,
      'Edited beginning — still the same response id.',
    );
  });

  test('skipped and answered mix preserves gaps without fabricating text', () async {
    final id = await startSession();

    var step = await advanceOnce(id);
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        responseId: StoryBuilderResponseId.generate(),
        promptId: step.currentPrompt!.id,
        text: 'Beginning.',
      ),
    );

    step = await advanceOnce(id);
    await skip.execute(
      SkipStoryBuilderPromptRequest(
        sessionId: id,
        responseId: StoryBuilderResponseId.generate(),
        promptId: step.currentPrompt!.id,
      ),
    );

    step = await advanceOnce(id);
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        responseId: StoryBuilderResponseId.generate(),
        promptId: step.currentPrompt!.id,
        text: 'Importance.',
      ),
    );

    final structure = (await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(sessionId: id),
    ) as Success<DeterministicStoryStructure>)
        .value;

    expect(
      structure.sectionForRole(StoryBuilderNarrativeRole.beginning)!
          .hasSourceMaterial,
      isTrue,
    );
    expect(
      structure.sectionForRole(StoryBuilderNarrativeRole.challenge)!.wasSkipped,
      isTrue,
    );
    expect(
      structure.sectionForRole(StoryBuilderNarrativeRole.challenge)!
          .hasSourceMaterial,
      isFalse,
    );
    expect(
      structure.sectionForRole(StoryBuilderNarrativeRole.importance)!
          .hasSourceMaterial,
      isTrue,
    );
    expect(
      structure.sectionForRole(StoryBuilderNarrativeRole.struggle)!.isEmpty,
      isTrue,
    );
    expect(structure.populatedSectionCount, 2);
    expect(structure.skippedSectionCount, 1);
    expect(structure.emptySectionCount, 8);
  });

  test('rejects abandoned sessions', () async {
    final id = await startSession();
    await abandon.execute(
      StoryBuilderSessionIdRequest(sessionId: id),
    );

    final result = await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(sessionId: id),
    );

    expect(result, isA<Failure<DeterministicStoryStructure>>());
    expect(
      (result as Failure<DeterministicStoryStructure>).error,
      contains('abandoned'),
    );
  });

  test('fails when session is missing', () async {
    final result = await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(
        sessionId: StoryBuilderSessionId.generate(),
      ),
    );

    expect(result, isA<Failure<DeterministicStoryStructure>>());
    expect(
      (result as Failure<DeterministicStoryStructure>).error,
      contains('not found'),
    );
  });

  test('does not persist structure — rebuild reflects current session', () async {
    final id = await startSession();
    final step = await advanceOnce(id);
    final responseId = StoryBuilderResponseId.generate();
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        responseId: responseId,
        promptId: step.currentPrompt!.id,
        text: 'First.',
      ),
    );

    final first = (await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(sessionId: id),
    ) as Success<DeterministicStoryStructure>)
        .value;
    expect(first.populatedSectionCount, 1);

    final step2 = await advanceOnce(id);
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        responseId: StoryBuilderResponseId.generate(),
        promptId: step2.currentPrompt!.id,
        text: 'Second.',
      ),
    );

    final second = (await buildStructure.execute(
      BuildDeterministicStoryStructureRequest(sessionId: id),
    ) as Success<DeterministicStoryStructure>)
        .value;
    expect(second.populatedSectionCount, 2);
    expect(identical(first, second), isFalse);
  });
}
