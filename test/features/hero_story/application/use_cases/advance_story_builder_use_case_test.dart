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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_builder_response_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
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

  test('full guided path completes session without creating a Story', () async {
    final id = await startSession();
    for (var i = 0; i < 11; i++) {
      final advanced = await advance.execute(
        AdvanceStoryBuilderRequest(sessionId: id),
      );
      expect(advanced, isA<Success<AdvanceStoryBuilderResult>>());
      final step = (advanced as Success<AdvanceStoryBuilderResult>).value;
      expect(step.questioningComplete, isFalse);
      expect(step.currentPrompt, isNotNull);
      expect(step.session.storyId, isNull);

      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: id,
          responseId: StoryBuilderResponseId.generate(),
          promptId: step.currentPrompt!.id,
          text: 'Hero words for step $i',
        ),
      );
    }

    final done = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: id),
    );
    final result = (done as Success<AdvanceStoryBuilderResult>).value;
    expect(result.questioningComplete, isTrue);
    expect(result.session.status, StoryBuilderSessionStatus.completed);
    expect(result.session.storyId, isNull);
    expect(result.session.responses, hasLength(11));

    final reloaded = await repository.findById(id);
    expect(reloaded!.status, StoryBuilderSessionStatus.completed);
    expect(reloaded.responses.first.text, 'Hero words for step 0');
  });

  test('skip, edit, pause/resume round-trip', () async {
    final id = await startSession();
    var step = (await advance.execute(AdvanceStoryBuilderRequest(sessionId: id))
            as Success<AdvanceStoryBuilderResult>)
        .value;
    await skip.execute(
      SkipStoryBuilderPromptRequest(
        sessionId: id,
        responseId: StoryBuilderResponseId.generate(),
        promptId: step.currentPrompt!.id,
      ),
    );

    step = (await advance.execute(AdvanceStoryBuilderRequest(sessionId: id))
            as Success<AdvanceStoryBuilderResult>)
        .value;
    final responseId = StoryBuilderResponseId.generate();
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        responseId: responseId,
        promptId: step.currentPrompt!.id,
        text: 'Original',
      ),
    );
    await edit.execute(
      EditStoryBuilderResponseRequest(
        sessionId: id,
        responseId: responseId,
        text: 'Edited original — still my voice',
      ),
    );

    final session = await repository.findById(id);
    session!.pause();
    await repository.save(session);

    final resumed = await repository.findById(id);
    expect(resumed!.status, StoryBuilderSessionStatus.paused);
    expect(resumed.responses.first.skipped, isTrue);
    expect(
      resumed.responses[1].text,
      'Edited original — still my voice',
    );

    final next = (await advance.execute(AdvanceStoryBuilderRequest(sessionId: id))
            as Success<AdvanceStoryBuilderResult>)
        .value;
    expect(next.session.status, StoryBuilderSessionStatus.inProgress);
    expect(next.currentPrompt!.ordinal, 2);
  });
}
