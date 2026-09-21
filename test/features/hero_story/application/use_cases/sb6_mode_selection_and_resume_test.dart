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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/list_resumable_story_builder_sessions_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_builder_session_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_resumable_story_builder_sessions_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/pause_story_builder_session_use_case.dart';
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
  late PauseStoryBuilderSessionUseCase pause;
  late ListResumableStoryBuilderSessionsUseCase listResumable;

  setUp(() {
    repository = InMemoryStoryBuilderSessionRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    start = StartStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    advance = AdvanceStoryBuilderUseCase(
      sessionRepository: repository,
      strategyResolver: const DefaultStoryBuilderQuestionStrategyResolver(),
      eventBus: eventBus,
    );
    answer = AnswerStoryBuilderPromptUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    pause = PauseStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    listResumable = ListResumableStoryBuilderSessionsUseCase(
      sessionRepository: repository,
    );
  });

  test('guided session stores mode and survives reload', () async {
    final sessionId = StoryBuilderSessionId.generate();
    final heroId = HeroId.generate();
    final intent = StoryBuilderIntent(
      purpose: StoryBuilderPurpose.shareALesson,
      themes: const [StoryBuilderTheme.courage],
    );

    final started = await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: heroId,
        mode: StoryBuilderMode.guided,
        intent: intent,
      ),
    );
    final session = (started as Success<StoryBuilderSession>).value;
    expect(session.mode, StoryBuilderMode.guided);
    expect(session.intent.purpose, StoryBuilderPurpose.shareALesson);
    expect(session.intent.themes, [StoryBuilderTheme.courage]);

    final reloaded = await repository.findById(sessionId);
    expect(reloaded!.mode, StoryBuilderMode.guided);
    expect(reloaded.intent.purpose, StoryBuilderPurpose.shareALesson);
    expect(reloaded.intent.themes, [StoryBuilderTheme.courage]);
  });

  test('ai session stores mode without invoking AI strategy until advance',
      () async {
    final sessionId = StoryBuilderSessionId.generate();
    final started = await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: HeroId.generate(),
        mode: StoryBuilderMode.ai,
      ),
    );
    final session = (started as Success<StoryBuilderSession>).value;
    expect(session.mode, StoryBuilderMode.ai);

    final advanced = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: sessionId),
    );
    expect(advanced, isA<Failure>());
    expect(
      (advanced as Failure).error,
      contains('AI Story Builder is not available'),
    );
  });

  test('resume after pause keeps responses and response ids', () async {
    final sessionId = StoryBuilderSessionId.generate();
    final heroId = HeroId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: heroId,
        mode: StoryBuilderMode.guided,
        intent: StoryBuilderIntent.purposeOnly(
          StoryBuilderPurpose.inspireSomeone,
        ),
      ),
    );

    final first = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: sessionId),
    );
    final firstPrompt =
        (first as Success<AdvanceStoryBuilderResult>).value.currentPrompt!;
    final responseId = StoryBuilderResponseId.generate();
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: sessionId,
        responseId: responseId,
        promptId: firstPrompt.id,
        text: 'It started on a quiet Tuesday.',
      ),
    );

    final second = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: sessionId),
    );
    final secondPrompt =
        (second as Success<AdvanceStoryBuilderResult>).value.currentPrompt!;
    expect(secondPrompt.id, isNot(firstPrompt.id));

    await pause.execute(StoryBuilderSessionIdRequest(sessionId: sessionId));

    final listed = await listResumable.execute(
      ListResumableStoryBuilderSessionsRequest(heroId: heroId),
    );
    final resumable = (listed as Success<List<StoryBuilderSession>>).value;
    expect(resumable, hasLength(1));
    expect(resumable.first.id, sessionId);
    expect(resumable.first.status, StoryBuilderSessionStatus.paused);
    expect(resumable.first.responses.single.id, responseId);
    expect(resumable.first.intent.purpose, StoryBuilderPurpose.inspireSomeone);

    final resumedAdvance = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: sessionId),
    );
    final resumed =
        (resumedAdvance as Success<AdvanceStoryBuilderResult>).value;
    expect(resumed.session.status, StoryBuilderSessionStatus.inProgress);
    expect(resumed.currentPrompt!.id, secondPrompt.id);
    expect(resumed.session.responses.single.id, responseId);
    expect(resumed.session.mode, StoryBuilderMode.guided);
  });

  test('completed sessions are not listed as resumable', () async {
    final sessionId = StoryBuilderSessionId.generate();
    final heroId = HeroId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: heroId,
        mode: StoryBuilderMode.guided,
      ),
    );

    for (var i = 0; i < 11; i++) {
      final advanced = await advance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      final result = (advanced as Success<AdvanceStoryBuilderResult>).value;
      if (result.questioningComplete) {
        break;
      }
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          responseId: StoryBuilderResponseId.generate(),
          promptId: result.currentPrompt!.id,
          text: 'Answer $i',
        ),
      );
    }

    final listed = await listResumable.execute(
      ListResumableStoryBuilderSessionsRequest(heroId: heroId),
    );
    expect((listed as Success<List<StoryBuilderSession>>).value, isEmpty);

    final completed = await repository.findById(sessionId);
    expect(completed!.status, StoryBuilderSessionStatus.completed);
  });

  test('multiple resumable sessions per hero are preserved', () async {
    final heroId = HeroId.generate();
    final firstId = StoryBuilderSessionId.generate();
    final secondId = StoryBuilderSessionId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: firstId,
        heroId: heroId,
        mode: StoryBuilderMode.guided,
      ),
    );
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: secondId,
        heroId: heroId,
        mode: StoryBuilderMode.guided,
      ),
    );

    final listed = await listResumable.execute(
      ListResumableStoryBuilderSessionsRequest(heroId: heroId),
    );
    final sessions = (listed as Success<List<StoryBuilderSession>>).value;
    expect(sessions.map((s) => s.id), containsAll([firstId, secondId]));
  });
}
