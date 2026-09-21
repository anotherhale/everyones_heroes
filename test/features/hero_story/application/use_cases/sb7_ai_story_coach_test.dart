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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/advance_story_builder_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_mode_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_mode_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_builder_coach_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_builder_coach_response_parser.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_builder_session_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStoryBuilderSessionRepository repository;
  late EventBus eventBus;
  late InMemoryStoryBuilderCoachAdapter coach;
  late StoryBuilderQuestionStrategyResolver resolver;
  late StartStoryBuilderSessionUseCase start;
  late AdvanceStoryBuilderUseCase advance;
  late AnswerStoryBuilderPromptUseCase answer;
  late SetStoryBuilderModeUseCase setMode;

  setUp(() {
    repository = InMemoryStoryBuilderSessionRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    coach = InMemoryStoryBuilderCoachAdapter();
    resolver = DefaultStoryBuilderQuestionStrategyResolver(
      aiStrategy: AiStoryBuilderQuestionStrategy(coach: coach),
    );
    start = StartStoryBuilderSessionUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    advance = AdvanceStoryBuilderUseCase(
      sessionRepository: repository,
      strategyResolver: resolver,
      eventBus: eventBus,
    );
    answer = AnswerStoryBuilderPromptUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    setMode = SetStoryBuilderModeUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
  });

  group('strategy resolution', () {
    test('ai mode resolves to AiStoryBuilderQuestionStrategy', () {
      final strategy = resolver.resolve(StoryBuilderMode.ai);
      expect(strategy, isA<AiStoryBuilderQuestionStrategy>());
      expect(strategy, isNot(isA<DeterministicStoryBuilderQuestionStrategy>()));
    });

    test('guided mode still resolves to deterministic strategy', () {
      expect(
        resolver.resolve(StoryBuilderMode.guided),
        isA<DeterministicStoryBuilderQuestionStrategy>(),
      );
    });
  });

  group('AI request construction', () {
    test('includes purpose, themes, prompts, responses — not unrelated data', () async {
      final sessionId = StoryBuilderSessionId.generate();
      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: HeroId.generate(),
          mode: StoryBuilderMode.ai,
          intent: StoryBuilderIntent(
            purpose: StoryBuilderPurpose.inspireSomeone,
            themes: const [
              StoryBuilderTheme.overcomingAdversity,
              StoryBuilderTheme.perseverance,
            ],
          ),
        ),
      );

      final first = await advance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      final prompt =
          (first as Success<AdvanceStoryBuilderResult>).value.currentPrompt!;
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          responseId: StoryBuilderResponseId.generate(),
          promptId: prompt.id,
          text: 'I was scared as hell and didn\'t know what to do.',
        ),
      );

      final session = await repository.findById(sessionId);
      final request = AiStoryBuilderQuestionStrategy.buildCoachRequest(session!);

      expect(request.purpose, StoryBuilderPurpose.inspireSomeone);
      expect(
        request.themes,
        containsAll([
          StoryBuilderTheme.overcomingAdversity,
          StoryBuilderTheme.perseverance,
        ]),
      );
      expect(request.turns, isNotEmpty);
      expect(request.turns.first.promptText, prompt.text);
      expect(
        request.turns.first.responseText,
        'I was scared as hell and didn\'t know what to do.',
      );

      final encoded = request.toString();
      expect(encoded.contains('OPENAI'), isFalse);
      expect(encoded.contains('Bearer'), isFalse);
      expect(encoded.contains('/tmp'), isFalse);
    });
  });

  group('structured response parsing', () {
    test('parses valid response', () {
      final suggestion = StoryBuilderCoachResponseParser.parse('''
        {
          "question": "What happened next?",
          "narrativeRole": "turningPoint",
          "reason": "explore_pivot",
          "readyToComplete": false
        }
      ''');
      expect(suggestion.question, 'What happened next?');
      expect(suggestion.narrativeRole, StoryBuilderNarrativeRole.turningPoint);
      expect(suggestion.reason, 'explore_pivot');
      expect(suggestion.readyToComplete, isFalse);
    });

    test('rejects missing question when not ready', () {
      expect(
        () => StoryBuilderCoachResponseParser.parse('{"readyToComplete":false}'),
        throwsA(isA<StoryBuilderCoachException>()),
      );
    });

    test('rejects invalid narrative role', () {
      expect(
        () => StoryBuilderCoachResponseParser.parse(
          '{"question":"Q?","narrativeRole":"notARole"}',
        ),
        throwsA(isA<StoryBuilderCoachException>()),
      );
    });

    test('rejects malformed JSON', () {
      expect(
        () => StoryBuilderCoachResponseParser.parse('not-json'),
        throwsA(isA<StoryBuilderCoachException>()),
      );
    });

    test('allows readyToComplete without question', () {
      final suggestion = StoryBuilderCoachResponseParser.parse(
        '{"readyToComplete":true,"question":""}',
      );
      expect(suggestion.readyToComplete, isTrue);
      expect(suggestion.question, isNull);
    });
  });

  group('question identity and hero voice', () {
    test('application assigns stable AI prompt ids; hero text preserved', () async {
      final ids = <StoryBuilderPromptId>[];
      final strategy = AiStoryBuilderQuestionStrategy(
        coach: InMemoryStoryBuilderCoachAdapter(
          suggestions: const [
            StoryBuilderCoachSuggestion(
              question: 'Where did it begin?',
              narrativeRole: StoryBuilderNarrativeRole.beginning,
            ),
            StoryBuilderCoachSuggestion(
              question: 'What made you keep going?',
              narrativeRole: StoryBuilderNarrativeRole.decision,
            ),
          ],
        ),
        promptIdGenerator: () {
          final id = StoryBuilderPromptId.generate();
          ids.add(id);
          return id;
        },
      );
      final localResolver = DefaultStoryBuilderQuestionStrategyResolver(
        aiStrategy: strategy,
      );
      final localAdvance = AdvanceStoryBuilderUseCase(
        sessionRepository: repository,
        strategyResolver: localResolver,
        eventBus: eventBus,
      );

      final sessionId = StoryBuilderSessionId.generate();
      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: HeroId.generate(),
          mode: StoryBuilderMode.ai,
        ),
      );

      final first = await localAdvance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      final firstPrompt =
          (first as Success<AdvanceStoryBuilderResult>).value.currentPrompt!;
      expect(firstPrompt.id, ids.first);
      expect(firstPrompt.source, StoryBuilderPromptSource.aiCoach);

      const heroText = 'I almost quit.';
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          responseId: StoryBuilderResponseId.generate(),
          promptId: firstPrompt.id,
          text: heroText,
        ),
      );

      final second = await localAdvance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      final secondPrompt =
          (second as Success<AdvanceStoryBuilderResult>).value.currentPrompt!;
      expect(secondPrompt.id, ids[1]);
      expect(secondPrompt.id, isNot(firstPrompt.id));

      final session = await repository.findById(sessionId);
      expect(session!.responses.single.text, heroText);
      expect(session.mode, StoryBuilderMode.ai);
    });
  });

  group('persistence / resume', () {
    test('AI session rebuilds coach context after repository recreation', () async {
      final sessionId = StoryBuilderSessionId.generate();
      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: HeroId.generate(),
          mode: StoryBuilderMode.ai,
          intent: StoryBuilderIntent.purposeOnly(
            StoryBuilderPurpose.shareALesson,
          ),
        ),
      );
      final first = await advance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      final prompt =
          (first as Success<AdvanceStoryBuilderResult>).value.currentPrompt!;
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          responseId: StoryBuilderResponseId.generate(),
          promptId: prompt.id,
          text: 'The lesson was patience.',
        ),
      );

      final original = await repository.findById(sessionId);
      final json = StoryBuilderSessionSnapshotMapper.toJson(original!);
      final restored = StoryBuilderSessionSnapshotMapper.fromJson(json);
      expect(restored.mode, StoryBuilderMode.ai);
      expect(restored.prompts.single.source, StoryBuilderPromptSource.aiCoach);
      expect(restored.responses.single.text, 'The lesson was patience.');

      final request = AiStoryBuilderQuestionStrategy.buildCoachRequest(restored);
      expect(request.purpose, StoryBuilderPurpose.shareALesson);
      expect(request.turns.single.responseText, 'The lesson was patience.');
    });
  });

  group('failure handling', () {
    test('coach failure does not lose answers or silently switch mode', () async {
      final failingCoach = InMemoryStoryBuilderCoachAdapter(
        forcedFailureMessage: 'proxy unavailable',
      );
      final failingResolver = DefaultStoryBuilderQuestionStrategyResolver(
        aiStrategy: AiStoryBuilderQuestionStrategy(coach: failingCoach),
      );
      // First use working coach, then swap repository session and failing advance.
      final sessionId = StoryBuilderSessionId.generate();
      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: HeroId.generate(),
          mode: StoryBuilderMode.ai,
        ),
      );

      final workingAdvance = AdvanceStoryBuilderUseCase(
        sessionRepository: repository,
        strategyResolver: DefaultStoryBuilderQuestionStrategyResolver(
          aiStrategy: AiStoryBuilderQuestionStrategy(
            coach: InMemoryStoryBuilderCoachAdapter(
              forcedSuggestion: const StoryBuilderCoachSuggestion(
                question: 'What happened first?',
                narrativeRole: StoryBuilderNarrativeRole.beginning,
              ),
            ),
          ),
        ),
        eventBus: eventBus,
      );
      final first = await workingAdvance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      final prompt =
          (first as Success<AdvanceStoryBuilderResult>).value.currentPrompt!;
      await answer.execute(
        AnswerStoryBuilderPromptRequest(
          sessionId: sessionId,
          responseId: StoryBuilderResponseId.generate(),
          promptId: prompt.id,
          text: 'Keep this answer safe.',
        ),
      );

      final failingAdvance = AdvanceStoryBuilderUseCase(
        sessionRepository: repository,
        strategyResolver: failingResolver,
        eventBus: eventBus,
      );
      final failed = await failingAdvance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      expect(failed, isA<Failure>());
      expect((failed as Failure).error, contains('proxy unavailable'));

      final session = await repository.findById(sessionId);
      expect(session!.mode, StoryBuilderMode.ai);
      expect(session.responses.single.text, 'Keep this answer safe.');
    });

    test('explicit guided recovery changes mode only on user decision', () async {
      final sessionId = StoryBuilderSessionId.generate();
      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: HeroId.generate(),
          mode: StoryBuilderMode.ai,
        ),
      );
      expect((await repository.findById(sessionId))!.mode, StoryBuilderMode.ai);

      final switched = await setMode.execute(
        SetStoryBuilderModeRequest(
          sessionId: sessionId,
          mode: StoryBuilderMode.guided,
        ),
      );
      expect(switched, isA<Success<StoryBuilderSession>>());
      expect(
        (switched as Success<StoryBuilderSession>).value.mode,
        StoryBuilderMode.guided,
      );
    });

    test('malformed coach output becomes Failure without mode change', () async {
      final badCoach = _MalformedCoach();
      final badAdvance = AdvanceStoryBuilderUseCase(
        sessionRepository: repository,
        strategyResolver: DefaultStoryBuilderQuestionStrategyResolver(
          aiStrategy: AiStoryBuilderQuestionStrategy(coach: badCoach),
        ),
        eventBus: eventBus,
      );
      final sessionId = StoryBuilderSessionId.generate();
      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: HeroId.generate(),
          mode: StoryBuilderMode.ai,
        ),
      );
      final result = await badAdvance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      expect(result, isA<Failure>());
      expect((await repository.findById(sessionId))!.mode, StoryBuilderMode.ai);
    });
  });

  group('guided regression', () {
    test('deterministic path unchanged through resolver', () async {
      final sessionId = StoryBuilderSessionId.generate();
      await start.execute(
        StartStoryBuilderSessionRequest(
          sessionId: sessionId,
          heroId: HeroId.generate(),
          mode: StoryBuilderMode.guided,
        ),
      );
      final first = await advance.execute(
        AdvanceStoryBuilderRequest(sessionId: sessionId),
      );
      final prompt =
          (first as Success<AdvanceStoryBuilderResult>).value.currentPrompt!;
      expect(prompt.id, DeterministicStoryBuilderCatalog.beginningId);
      expect(prompt.source, StoryBuilderPromptSource.catalog);
    });
  });
}

final class _MalformedCoach implements StoryBuilderCoachPort {
  @override
  Future<StoryBuilderCoachSuggestion> suggestNextQuestion(
    StoryBuilderCoachRequest request,
  ) async {
    throw const StoryBuilderCoachException('Malformed AI Story Coach response');
  }
}
