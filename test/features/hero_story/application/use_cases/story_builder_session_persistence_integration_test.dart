import 'dart:io';

import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/advance_story_builder_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/build_deterministic_story_structure_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_builder_response_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_intent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_builder_session_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/build_deterministic_story_structure_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_story_builder_response_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/pause_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_intent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/skip_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_builder_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late FileStoryBuilderSessionRepository repository;
  late EventBus eventBus;
  late StartStoryBuilderSessionUseCase start;
  late AdvanceStoryBuilderUseCase advance;
  late AnswerStoryBuilderPromptUseCase answer;
  late SkipStoryBuilderPromptUseCase skip;
  late EditStoryBuilderResponseUseCase edit;
  late SetStoryBuilderIntentUseCase setIntent;
  late PauseStoryBuilderSessionUseCase pause;
  late CompleteStoryBuilderSessionUseCase complete;
  late BuildDeterministicStoryStructureUseCase buildStructure;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('eh-sb5-integration-');
    repository = FileStoryBuilderSessionRepository(rootDirectory: tempDir);
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
    setIntent = SetStoryBuilderIntentUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    pause = PauseStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    complete = CompleteStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    buildStructure = BuildDeterministicStoryStructureUseCase(
      sessionRepository: repository,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<AdvanceStoryBuilderResult> advanceOnce(
    StoryBuilderSessionId id,
  ) async {
    final result = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: id),
    );
    return (result as Success<AdvanceStoryBuilderResult>).value;
  }

  test(
    'use cases → durable save → reload → provenance-preserving structure',
    () async {
      const sessionId = StoryBuilderSessionId('sb5-session');
      const heroId = HeroId('hero-sb5');
      const responseA = StoryBuilderResponseId('resp-a');
      const responseB = StoryBuilderResponseId('resp-b');
      const responseC = StoryBuilderResponseId('resp-c');

      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: heroId,
          mode: StoryBuilderMode.guided,
        ),
      );

      await setIntent.execute(
        SetStoryBuilderIntentRequest(
          sessionId: sessionId,
          intent: StoryBuilderIntent(
            purpose: StoryBuilderPurpose.helpSomeoneFacingSomethingSimilar,
            themes: const [
              StoryBuilderTheme.courage,
              StoryBuilderTheme.secondChances,
            ],
          ),
        ),
      );

      final first = await advanceOnce(sessionId);
      expect(first.currentPrompt, isNotNull);
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          promptId: first.currentPrompt!.id,
          responseId: responseA,
          text: 'It began with uncertainty.',
        ),
      );

      final second = await advanceOnce(sessionId);
      await skip.execute(
        SkipStoryBuilderPromptRequest(
          sessionId: sessionId,
          promptId: second.currentPrompt!.id,
          responseId: responseB,
        ),
      );

      final third = await advanceOnce(sessionId);
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          promptId: third.currentPrompt!.id,
          responseId: responseC,
          text: 'It mattered because others were watching.',
        ),
      );

      await edit.execute(
        EditStoryBuilderResponseRequest(
          sessionId: sessionId,
          responseId: responseA,
          text: 'It began with quiet uncertainty.',
        ),
      );

      await pause.execute(StoryBuilderSessionIdRequest(sessionId: sessionId));

      // Simulate app restart: new repository + use case on same disk root.
      final restarted = FileStoryBuilderSessionRepository(
        rootDirectory: tempDir,
      );
      final loaded = await restarted.findById(sessionId);
      expect(loaded, isNotNull);
      expect(loaded!.status, StoryBuilderSessionStatus.paused);
      expect(
        loaded.intent.purpose,
        StoryBuilderPurpose.helpSomeoneFacingSomethingSimilar,
      );
      expect(loaded.intent.themes, [
        StoryBuilderTheme.courage,
        StoryBuilderTheme.secondChances,
      ]);
      expect(loaded.responses, hasLength(3));
      expect(loaded.responses[0].id, responseA);
      expect(loaded.responses[0].text, 'It began with quiet uncertainty.');
      expect(loaded.responses[1].id, responseB);
      expect(loaded.responses[1].skipped, isTrue);
      expect(loaded.responses[2].id, responseC);

      final structureUseCase = BuildDeterministicStoryStructureUseCase(
        sessionRepository: restarted,
      );
      final structureResult = await structureUseCase.execute(
        BuildDeterministicStoryStructureRequest(sessionId: sessionId),
      );
      final structure =
          (structureResult as Success<DeterministicStoryStructure>).value;

      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.beginning)!
            .sourceResponseIds,
        [responseA],
      );
      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.challenge)!
            .sourceResponseIds,
        [responseB],
      );
      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.challenge)!
            .wasSkipped,
        isTrue,
      );
      expect(
        structure.sectionForRole(StoryBuilderNarrativeRole.importance)!
            .sourceResponseIds,
        [responseC],
      );

      // Resume after reload: strategy derives next question from responses.
      final resumeAdvance = AdvanceStoryBuilderUseCase(
        sessionRepository: restarted,
        questionStrategy: const DeterministicStoryBuilderQuestionStrategy(),
        eventBus: eventBus,
      );
      // Must resume first (paused → inProgress).
      loaded.resume();
      await restarted.save(loaded);

      final next = await resumeAdvance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      final nextResult = (next as Success<AdvanceStoryBuilderResult>).value;
      expect(nextResult.currentPrompt, isNotNull);
      expect(nextResult.currentPrompt!.id, DeterministicStoryBuilderCatalog.struggleId);
    },
  );

  test('active → answer → persist → reload keeps inProgress', () async {
    const sessionId = StoryBuilderSessionId('active-session');
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: const HeroId('hero-1'),
      ),
    );
    final presented = await advanceOnce(sessionId);
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: sessionId,
        promptId: presented.currentPrompt!.id,
        responseId: const StoryBuilderResponseId('r1'),
        text: 'Active answer',
      ),
    );

    final restarted = FileStoryBuilderSessionRepository(
      rootDirectory: tempDir,
    );
    final loaded = await restarted.findById(sessionId);
    expect(loaded!.status, StoryBuilderSessionStatus.inProgress);
    expect(loaded.responses.single.text, 'Active answer');
  });

  test('completed session survives durable reload', () async {
    const sessionId = StoryBuilderSessionId('complete-session');
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: const HeroId('hero-1'),
      ),
    );
    await complete.execute(StoryBuilderSessionIdRequest(sessionId: sessionId));

    final restarted = FileStoryBuilderSessionRepository(
      rootDirectory: tempDir,
    );
    final loaded = await restarted.findById(sessionId);
    expect(loaded!.status, StoryBuilderSessionStatus.completed);
    expect(loaded.isComplete, isTrue);
  });

  test('abandoned session survives durable reload', () async {
    const sessionId = StoryBuilderSessionId('abandon-session');
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: const HeroId('hero-1'),
      ),
    );
    final session = await repository.findById(sessionId);
    session!.abandon();
    await repository.save(session);

    final restarted = FileStoryBuilderSessionRepository(
      rootDirectory: tempDir,
    );
    final loaded = await restarted.findById(sessionId);
    expect(loaded!.status, StoryBuilderSessionStatus.abandoned);
  });

  test('intent uncertainty values survive durable reload', () async {
    const sessionId = StoryBuilderSessionId('intent-unsure');
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: const HeroId('hero-1'),
      ),
    );
    await setIntent.execute(
      SetStoryBuilderIntentRequest(
        sessionId: sessionId,
        intent: StoryBuilderIntent(
          purpose: StoryBuilderPurpose.notSureYet,
          themesUnsure: true,
        ),
      ),
    );

    final restarted = FileStoryBuilderSessionRepository(
      rootDirectory: tempDir,
    );
    final loaded = await restarted.findById(sessionId);
    expect(loaded!.intent.purpose, StoryBuilderPurpose.notSureYet);
    expect(loaded.intent.themesUnsure, isTrue);
    expect(loaded.intent.themes, isEmpty);
  });

  test(
    'structure after reload matches structure before persist',
    () async {
      const sessionId = StoryBuilderSessionId('structure-parity');
      const responseId = StoryBuilderResponseId('resp-parity');

      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: const HeroId('hero-1'),
        ),
      );
      final presented = await advanceOnce(sessionId);
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          promptId: presented.currentPrompt!.id,
          responseId: responseId,
          text: 'Parity answer',
        ),
      );

      final before = await buildStructure.execute(
        BuildDeterministicStoryStructureRequest(sessionId: sessionId),
      );
      final beforeStructure =
          (before as Success<DeterministicStoryStructure>).value;

      final restarted = FileStoryBuilderSessionRepository(
        rootDirectory: tempDir,
      );
      final afterUseCase = BuildDeterministicStoryStructureUseCase(
        sessionRepository: restarted,
      );
      final after = await afterUseCase.execute(
        BuildDeterministicStoryStructureRequest(sessionId: sessionId),
      );
      final afterStructure =
          (after as Success<DeterministicStoryStructure>).value;

      expect(afterStructure, beforeStructure);
      expect(
        afterStructure
            .sectionForRole(StoryBuilderNarrativeRole.beginning)!
            .sourceResponseIds
            .single,
        responseId,
      );
    },
  );
}
