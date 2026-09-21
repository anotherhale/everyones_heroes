import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_builder_response_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/present_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_intent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_builder_session_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_story_builder_response_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/pause_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/present_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/resume_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_intent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/skip_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStoryBuilderSessionRepository repository;
  late EventBus eventBus;
  late StartStoryBuilderSessionUseCase start;
  late PresentStoryBuilderPromptUseCase present;
  late AnswerStoryBuilderPromptUseCase answer;
  late SkipStoryBuilderPromptUseCase skip;
  late EditStoryBuilderResponseUseCase edit;
  late SetStoryBuilderIntentUseCase setIntent;
  late PauseStoryBuilderSessionUseCase pause;
  late ResumeStoryBuilderSessionUseCase resume;
  late CompleteStoryBuilderSessionUseCase complete;
  late GetStoryBuilderSessionUseCase get;

  setUp(() {
    repository = InMemoryStoryBuilderSessionRepository();
    final store = InMemoryEventStore();
    eventBus = InMemoryEventBus(
      eventStore: store,
      dispatcher: InMemoryEventDispatcher(),
    );

    start = StartStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    present = PresentStoryBuilderPromptUseCase(
      sessionRepository: repository,
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
    resume = ResumeStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    complete = CompleteStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    get = GetStoryBuilderSessionUseCase(sessionRepository: repository);
  });

  test('start → present → answer → pause → resume → complete flow', () async {
    final sessionId = StoryBuilderSessionId.generate();
    final heroId = HeroId.generate();

    final started = await start.execute(
      StartStoryBuilderSessionRequest(sessionId: sessionId, heroId: heroId),
    );
    expect(started, isA<Success<StoryBuilderSession>>());

    final prompt = StoryBuilderPrompt(
      id: StoryBuilderPromptId.generate(),
      text: 'What was happening when this began?',
      ordinal: 0,
    );
    expect(
      await present.execute(
        PresentStoryBuilderPromptRequest(sessionId: sessionId, prompt: prompt),
      ),
      isA<Success<StoryBuilderSession>>(),
    );

    final responseId = StoryBuilderResponseId.generate();
    expect(
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          responseId: responseId,
          promptId: prompt.id,
          text: 'Everything changed overnight.',
        ),
      ),
      isA<Success<StoryBuilderSession>>(),
    );

    expect(
      await setIntent.execute(
        SetStoryBuilderIntentRequest(
          sessionId: sessionId,
          intent: StoryBuilderIntent(purpose: 'Help someone feel less alone'),
        ),
      ),
      isA<Success<StoryBuilderSession>>(),
    );

    expect(
      await pause.execute(StoryBuilderSessionIdRequest(sessionId: sessionId)),
      isA<Success<StoryBuilderSession>>(),
    );
    expect(
      await resume.execute(StoryBuilderSessionIdRequest(sessionId: sessionId)),
      isA<Success<StoryBuilderSession>>(),
    );

    expect(
      await edit.execute(
        EditStoryBuilderResponseRequest(
          sessionId: sessionId,
          responseId: responseId,
          text: 'Everything changed overnight — and I had to adapt.',
        ),
      ),
      isA<Success<StoryBuilderSession>>(),
    );

    final completed = await complete.execute(
      StoryBuilderSessionIdRequest(sessionId: sessionId),
    );
    expect(completed, isA<Success<StoryBuilderSession>>());
    final session = (completed as Success<StoryBuilderSession>).value;
    expect(session.status, StoryBuilderSessionStatus.completed);
    expect(session.storyId, isNull);
    expect(session.responses.single.id, responseId);
    expect(
      session.responses.single.text,
      'Everything changed overnight — and I had to adapt.',
    );

    final loaded = await get.execute(
      StoryBuilderSessionIdRequest(sessionId: sessionId),
    );
    expect(loaded, isA<Success<StoryBuilderSession>>());
  });

  test('skip path and missing session failure', () async {
    final sessionId = StoryBuilderSessionId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: sessionId,
        heroId: HeroId.generate(),
      ),
    );
    final prompt = StoryBuilderPrompt(
      id: StoryBuilderPromptId.generate(),
      text: 'Optional detail',
      ordinal: 0,
    );
    await present.execute(
      PresentStoryBuilderPromptRequest(sessionId: sessionId, prompt: prompt),
    );

    final skipped = await skip.execute(
      SkipStoryBuilderPromptRequest(
        sessionId: sessionId,
        responseId: StoryBuilderResponseId.generate(),
        promptId: prompt.id,
      ),
    );
    expect(skipped, isA<Success<StoryBuilderSession>>());
    expect(
      (skipped as Success<StoryBuilderSession>).value.responses.single.skipped,
      isTrue,
    );

    final missing = await get.execute(
      StoryBuilderSessionIdRequest(
        sessionId: StoryBuilderSessionId.generate(),
      ),
    );
    expect(missing, isA<Failure>());
  });
}
