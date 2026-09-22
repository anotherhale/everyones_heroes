import 'dart:convert';

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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_intent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/understand_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_intent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/skip_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/understand_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_builder_understanding_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_builder_understanding_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_builder_understanding_response_parser.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late InMemoryStoryBuilderSessionRepository repository;
  late InMemoryStoryRepository storyRepository;
  late EventBus eventBus;
  late StartStoryBuilderSessionUseCase start;
  late AdvanceStoryBuilderUseCase advance;
  late AnswerStoryBuilderPromptUseCase answer;
  late SkipStoryBuilderPromptUseCase skip;
  late SetStoryBuilderIntentUseCase setIntent;
  late UnderstandStoryBuilderSessionUseCase understand;
  late InMemoryStoryBuilderUnderstandingAdapter understandingAdapter;

  setUp(() {
    repository = InMemoryStoryBuilderSessionRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    understandingAdapter = InMemoryStoryBuilderUnderstandingAdapter();
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
    skip = SkipStoryBuilderPromptUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    setIntent = SetStoryBuilderIntentUseCase(
      sessionRepository: repository,
      eventBus: eventBus,
    );
    understand = UnderstandStoryBuilderSessionUseCase(
      sessionRepository: repository,
      understandingPort: understandingAdapter,
    );
  });

  Future<StoryBuilderSessionId> startSession({
    StoryBuilderMode mode = StoryBuilderMode.guided,
  }) async {
    final id = StoryBuilderSessionId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: id,
        heroId: HeroId.generate(),
        mode: mode,
      ),
    );
    return id;
  }

  Future<AdvanceStoryBuilderResult> advanceOnce(
    StoryBuilderSessionId id,
  ) async {
    final result = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: id),
    );
    return (result as Success<AdvanceStoryBuilderResult>).value;
  }

  Future<void> answerCurrent(
    StoryBuilderSessionId id,
    String text, {
    StoryBuilderResponseId? responseId,
  }) async {
    final step = await advanceOnce(id);
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        promptId: step.currentPrompt!.id,
        responseId: responseId ?? StoryBuilderResponseId.generate(),
        text: text,
      ),
    );
  }

  group('deterministic understanding', () {
    test('creates understanding from valid session without mutating source',
        () async {
      final id = await startSession();
      await setIntent.execute(
        SetStoryBuilderIntentRequest(
          sessionId: id,
          intent: StoryBuilderIntent(
            purpose: StoryBuilderPurpose.inspireSomeone,
            themes: const [StoryBuilderTheme.perseverance],
          ),
        ),
      );

      final challengeResponseId = StoryBuilderResponseId('sb-response-challenge');
      // beginning
      await answerCurrent(id, 'It began on a rainy morning.');
      // challenge
      await answerCurrent(
        id,
        'I faced a hard challenge for years.',
        responseId: challengeResponseId,
      );
      // importance
      await answerCurrent(id, 'It mattered because my family counted on me.');

      final before = await repository.findById(id);
      final purposeBefore = before!.intent.purpose;
      final themesBefore = List.of(before.intent.themes);
      final responsesBefore = List.of(before.responses);
      final storyCountBefore = (await storyRepository.findAll()).length;

      final analyzedAt = DateTime.utc(2026, 9, 21, 12);
      final result = await understand.execute(
        UnderstandStoryBuilderSessionRequest(
          sessionId: id,
          analyzedAt: analyzedAt,
        ),
      );

      expect(result, isA<Success<StoryBuilderUnderstanding>>());
      final understanding =
          (result as Success<StoryBuilderUnderstanding>).value;

      expect(understanding.kind, StoryBuilderUnderstandingKind.deterministic);
      expect(understanding.sessionId, id);
      expect(understanding.structure.sectionCount, 11);
      expect(understanding.intentSnapshot.purpose, StoryBuilderPurpose.inspireSomeone);
      expect(
        understanding.themes.map((t) => t.theme),
        contains(StoryBuilderTheme.perseverance),
      );
      expect(
        understanding.themes.first.origin,
        UnderstoodThemeOrigin.sessionIntent,
      );
      expect(understanding.keyElements.challenge, isNotNull);
      expect(
        understanding.keyElements.challenge!.sourceResponseIds,
        [challengeResponseId],
      );
      expect(understanding.keyElements.challenge!.derivedInterpretation, isNull);
      expect(understanding.populatedNarrativeElementCount, 3);
      expect(understanding.derivedSummary, isNull);
      expect(understanding.providerLabel, 'deterministic');

      final after = await repository.findById(id);
      expect(after!.intent.purpose, purposeBefore);
      expect(after.intent.themes, themesBefore);
      expect(after.responses.length, responsesBefore.length);
      for (var i = 0; i < responsesBefore.length; i++) {
        expect(after.responses[i].id, responsesBefore[i].id);
        expect(after.responses[i].text, responsesBefore[i].text);
      }
      expect(after.storyId, isNull);
      expect((await storyRepository.findAll()).length, storyCountBefore);
    });

    test('maps SB.3 → SB.4 → SB.8 narrative roles with provenance', () async {
      final id = await startSession();
      final ids = <StoryBuilderNarrativeRole, StoryBuilderResponseId>{};

      for (final role in StoryBuilderNarrativeRole.values) {
        final step = await advanceOnce(id);
        expect(step.currentPrompt!.narrativeRole, role);
        final responseId = StoryBuilderResponseId('resp-${role.name}');
        ids[role] = responseId;
        await answer.execute(
          AnswerStoryBuilderPromptRequest(
            sessionId: id,
            promptId: step.currentPrompt!.id,
            responseId: responseId,
            text: 'Material for ${role.name}',
          ),
        );
      }

      final result = await understand.execute(
        UnderstandStoryBuilderSessionRequest(sessionId: id),
      );
      final understanding =
          (result as Success<StoryBuilderUnderstanding>).value;

      for (final role in StoryBuilderNarrativeRole.values) {
        final section = understanding.structure.sectionForRole(role)!;
        expect(section.hasSourceMaterial, isTrue);
        expect(section.sourceResponseIds, [ids[role]]);
        final element = understanding.narrativeElements
            .firstWhere((e) => e.narrativeRole == role);
        expect(element.sourceResponseIds, [ids[role]]);
      }

      expect(understanding.keyElements.turningPoint!.sourceResponseIds,
          [ids[StoryBuilderNarrativeRole.turningPoint]]);
      expect(
        understanding.significantEvents.map((e) => e.narrativeRole),
        containsAll([
          StoryBuilderNarrativeRole.turningPoint,
          StoryBuilderNarrativeRole.decision,
          StoryBuilderNarrativeRole.action,
          StoryBuilderNarrativeRole.outcome,
        ]),
      );
      for (final event in understanding.significantEvents) {
        expect(
          event.sourceResponseIds.every(
            (id) => ids.values.contains(id),
          ),
          isTrue,
        );
      }
    });

    test('handles skipped and partial sessions', () async {
      final id = await startSession();
      await answerCurrent(id, 'Beginning only.');
      final step = await advanceOnce(id);
      await skip.execute(
        SkipStoryBuilderPromptRequest(
          sessionId: id,
          promptId: step.currentPrompt!.id,
          responseId: StoryBuilderResponseId.generate(),
        ),
      );
      await answerCurrent(id, 'Importance mattered.');

      final result = await understand.execute(
        UnderstandStoryBuilderSessionRequest(sessionId: id),
      );
      final understanding =
          (result as Success<StoryBuilderUnderstanding>).value;

      expect(understanding.populatedNarrativeElementCount, 2);
      expect(
        understanding.structure
            .sectionForRole(StoryBuilderNarrativeRole.challenge)!
            .wasSkipped,
        isTrue,
      );
      expect(understanding.keyElements.challenge, isNull);
      expect(understanding.keyElements.struggle, isNull);
    });

    test('rejects empty material and abandoned sessions', () async {
      final emptyId = await startSession();
      final emptyResult = await understand.execute(
        UnderstandStoryBuilderSessionRequest(sessionId: emptyId),
      );
      expect(emptyResult, isA<Failure>());

      final abandonedId = await startSession();
      await answerCurrent(abandonedId, 'Some material.');
      final session = await repository.findById(abandonedId);
      session!.abandon();
      await repository.save(session);

      final abandonedResult = await understand.execute(
        UnderstandStoryBuilderSessionRequest(sessionId: abandonedId),
      );
      expect(abandonedResult, isA<Failure>());
    });

    test('does not create a Story', () async {
      final id = await startSession();
      await answerCurrent(id, 'Only response.');
      final beforeStories = await storyRepository.findAll();

      await understand.execute(
        UnderstandStoryBuilderSessionRequest(sessionId: id),
      );

      final afterStories = await storyRepository.findAll();
      expect(afterStories.length, beforeStories.length);
      final session = await repository.findById(id);
      expect(session!.storyId, isNull);
      expect(session.status, StoryBuilderSessionStatus.inProgress);
    });
  });

  group('AI-enhanced understanding', () {
    test('accepts valid AI draft with provenance', () async {
      final id = await startSession();
      final responseId = StoryBuilderResponseId('ai-resp-1');
      await answerCurrent(
        id,
        'I kept going with courage despite fear.',
        responseId: responseId,
      );

      final result = await understand.execute(
        UnderstandStoryBuilderSessionRequest(
          sessionId: id,
          kind: StoryBuilderUnderstandingKind.aiEnhanced,
        ),
      );
      expect(result, isA<Success<StoryBuilderUnderstanding>>());
      final understanding =
          (result as Success<StoryBuilderUnderstanding>).value;
      expect(understanding.isAiEnhanced, isTrue);
      expect(understanding.providerLabel, 'in_memory');
      expect(
        understanding.narrativeElements.every(
          (e) => e.sourceResponseIds.every((id) => id == responseId),
        ),
        isTrue,
      );
    });

    test('rejects unknown response IDs from AI', () async {
      final id = await startSession();
      await answerCurrent(id, 'Real material.');

      understand = UnderstandStoryBuilderSessionUseCase(
        sessionRepository: repository,
        understandingPort: InMemoryStoryBuilderUnderstandingAdapter(
          forcedDraft: StoryBuilderUnderstandingDraft(
            themes: [
              UnderstoodTheme(
                theme: StoryBuilderTheme.courage,
                origin: UnderstoodThemeOrigin.derivedFromResponses,
                sourceResponseIds: [
                  const StoryBuilderResponseId('does-not-exist'),
                ],
              ),
            ],
          ),
        ),
      );

      final result = await understand.execute(
        UnderstandStoryBuilderSessionRequest(
          sessionId: id,
          kind: StoryBuilderUnderstandingKind.aiEnhanced,
        ),
      );
      expect(result, isA<Failure>());
      expect(
        (result as Failure).error,
        contains('unknown response id'),
      );
      final session = await repository.findById(id);
      expect(session!.responses.single.text, 'Real material.');
    });

    test('rejects empty AI result and port failures without mutating session',
        () async {
      final id = await startSession();
      await answerCurrent(id, 'Keep me.');

      understand = UnderstandStoryBuilderSessionUseCase(
        sessionRepository: repository,
        understandingPort: InMemoryStoryBuilderUnderstandingAdapter(
          forcedDraft: const StoryBuilderUnderstandingDraft(),
        ),
      );
      final empty = await understand.execute(
        UnderstandStoryBuilderSessionRequest(
          sessionId: id,
          kind: StoryBuilderUnderstandingKind.aiEnhanced,
        ),
      );
      expect(empty, isA<Failure>());
      expect((empty as Failure).error, contains('empty'));

      understand = UnderstandStoryBuilderSessionUseCase(
        sessionRepository: repository,
        understandingPort: InMemoryStoryBuilderUnderstandingAdapter(
          forcedFailureMessage: 'proxy unavailable',
        ),
      );
      final failed = await understand.execute(
        UnderstandStoryBuilderSessionRequest(
          sessionId: id,
          kind: StoryBuilderUnderstandingKind.aiEnhanced,
        ),
      );
      expect(failed, isA<Failure>());
      expect((failed as Failure).error, contains('proxy unavailable'));

      final session = await repository.findById(id);
      expect(session!.responses.single.text, 'Keep me.');
      expect(session.status, StoryBuilderSessionStatus.inProgress);
    });

    test('AI unavailable when port missing', () async {
      final id = await startSession();
      await answerCurrent(id, 'Material.');
      understand = UnderstandStoryBuilderSessionUseCase(
        sessionRepository: repository,
      );
      final result = await understand.execute(
        UnderstandStoryBuilderSessionRequest(
          sessionId: id,
          kind: StoryBuilderUnderstandingKind.aiEnhanced,
        ),
      );
      expect(result, isA<Failure>());
      expect(
        (result as Failure).error,
        contains('unavailable'),
      );
    });
  });

  group('response parser', () {
    test('parses valid payload', () {
      final draft = StoryBuilderUnderstandingResponseParser.parse(
        jsonEncode({
          'themes': [
            {
              'theme': 'perseverance',
              'sourceResponseIds': ['r1'],
            },
          ],
          'narrativeElements': [
            {
              'narrativeRole': 'challenge',
              'sourceResponseIds': ['r1'],
              'derivedNote': 'Hero described a challenge.',
            },
          ],
          'keyElements': {
            'challenge': {
              'sourceResponseIds': ['r1'],
              'derivedInterpretation': 'A challenge was stated.',
            },
          },
          'significantEvents': [
            {
              'label': 'Turning point material',
              'sourceResponseIds': ['r1'],
              'narrativeRole': 'turningPoint',
            },
          ],
          'derivedSummary': 'Short derived analysis.',
        }),
      );
      expect(draft.themes.single.theme, StoryBuilderTheme.perseverance);
      expect(
        draft.narrativeElements.single.narrativeRole,
        StoryBuilderNarrativeRole.challenge,
      );
    });

    test('rejects malformed JSON, invalid theme, invalid role', () {
      expect(
        () => StoryBuilderUnderstandingResponseParser.parse('not-json'),
        throwsA(isA<StoryBuilderUnderstandingException>()),
      );
      expect(
        () => StoryBuilderUnderstandingResponseParser.parseMap({
          'themes': [
            {
              'theme': 'notARealTheme',
              'sourceResponseIds': ['r1'],
            },
          ],
        }),
        throwsA(
          isA<StoryBuilderUnderstandingException>().having(
            (e) => e.message,
            'message',
            contains('invalid theme'),
          ),
        ),
      );
      expect(
        () => StoryBuilderUnderstandingResponseParser.parseMap({
          'narrativeElements': [
            {
              'narrativeRole': 'plotTwist',
              'sourceResponseIds': ['r1'],
            },
          ],
        }),
        throwsA(
          isA<StoryBuilderUnderstandingException>().having(
            (e) => e.message,
            'message',
            contains('invalid narrative role'),
          ),
        ),
      );
    });
  });

  group('proxy adapter', () {
    test('maps valid proxy response', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/story-understanding');
        expect(request.headers['authorization'], 'Bearer secret');
        final body = jsonDecode(request.body) as Map;
        expect(body['responses'], isA<List>());
        return http.Response(
          jsonEncode({
            'themes': [
              {
                'theme': 'courage',
                'sourceResponseIds': ['r1'],
              },
            ],
            'narrativeElements': [
              {
                'narrativeRole': 'beginning',
                'sourceResponseIds': ['r1'],
              },
            ],
            'providerLabel': 'openai_via_eh_proxy',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final adapter = ProxyStoryBuilderUnderstandingAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
        authToken: 'secret',
      );

      final draft = await adapter.analyze(
        StoryBuilderUnderstandingRequest(
          responses: [
            StoryBuilderUnderstandingResponseItem(
              id: const StoryBuilderResponseId('r1'),
              ordinal: 0,
              text: 'hello',
            ),
          ],
        ),
      );
      expect(draft.themes.single.theme, StoryBuilderTheme.courage);
      expect(draft.providerLabel, 'openai_via_eh_proxy');
    });

    test('maps auth, timeout-like, and server failures', () async {
      final authAdapter = ProxyStoryBuilderUnderstandingAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: MockClient(
          (_) async => http.Response('{"error":"unauthorized"}', 401),
        ),
        authToken: 'bad',
      );
      await expectLater(
        authAdapter.analyze(const StoryBuilderUnderstandingRequest()),
        throwsA(
          isA<StoryBuilderUnderstandingException>().having(
            (e) => e.message,
            'message',
            contains('authentication'),
          ),
        ),
      );

      final failAdapter = ProxyStoryBuilderUnderstandingAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: MockClient(
          (_) async => http.Response('{"error":"boom"}', 500),
        ),
      );
      await expectLater(
        failAdapter.analyze(const StoryBuilderUnderstandingRequest()),
        throwsA(
          isA<StoryBuilderUnderstandingException>().having(
            (e) => e.message,
            'message',
            contains('proxy failed'),
          ),
        ),
      );
    });
  });

  group('guided independence', () {
    test('deterministic understanding does not require understanding port',
        () async {
      final id = await startSession();
      await answerCurrent(id, 'Offline material.');
      final offline = UnderstandStoryBuilderSessionUseCase(
        sessionRepository: repository,
      );
      final result = await offline.execute(
        UnderstandStoryBuilderSessionRequest(sessionId: id),
      );
      expect(result, isA<Success<StoryBuilderUnderstanding>>());
      expect(
        (result as Success<StoryBuilderUnderstanding>).value.isDeterministic,
        isTrue,
      );
    });
  });
}
