import 'dart:convert';

import 'package:eh_platform/eh_platform.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/view_models.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:eh_platform/src/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:eh_platform/src/life_journey/domain/enums/reflection_emotion.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern_type.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/rules/consistency_pattern_rule.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/evidence_source.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/strength.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

/// Builds an HTTP handler for H.2 in-memory tests with a fixed principal.
Handler lifeJourneyTestHandler({
  required LifeJourneyComponents components,
  required AuthenticatedPrincipal principal,
}) {
  return const Pipeline()
      .addMiddleware(correlationMiddleware())
      .addMiddleware((inner) {
        return (request) {
          return inner(
            request.change(
              context: {
                ...request.context,
                principalContextKey: principal,
              },
            ),
          );
        };
      })
      .addHandler(components.handler);
}

void main() {
  group('H.2 domain', () {
    test('ConsistencyPatternRule detects discipline evidence ≥3', () {
      final now = DateTime.utc(2026, 1, 1);
      final evidence = List.generate(
        3,
        (i) => BehavioralEvidence(
          type: BehavioralEvidenceType.discipline,
          source: ReflectionEvidenceSource(reflectionId: ReflectionId('r$i')),
          strength: const Strength(0.8),
          observedAt: now.add(Duration(days: i)),
        ),
      );

      final pattern = ConsistencyPatternRule().detect(evidence);
      expect(pattern, isNotNull);
      expect(pattern!.type, BehaviorPatternType.consistency);
      expect(pattern.observationCount, 3);
    });

    test('BehaviorPattern requires multiple observations', () {
      expect(
        () => BehaviorPattern(
          type: BehaviorPatternType.courage,
          strength: const Strength(0.5),
          supportingEvidence: [
            BehavioralEvidence(
              type: BehavioralEvidenceType.courage,
              source: ReflectionEvidenceSource(
                reflectionId: ReflectionId('r1'),
              ),
              strength: const Strength(0.5),
              observedAt: DateTime.utc(2026, 1, 1),
            ),
          ],
          firstObservedAt: DateTime.utc(2026, 1, 1),
          lastObservedAt: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('H.2 application (in-memory)', () {
    late LifeJourneyComponents lifeJourney;
    late EventStore eventStore;
    final userId = UserId('00000000-0000-4000-8000-000000000001');

    setUp(() {
      eventStore = InMemoryEventStore();
      final dispatcher = InMemoryEventDispatcher();
      final eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );
      lifeJourney = LifeJourneyModule.composeInMemory(
        eventBus: eventBus,
        eventDispatcher: dispatcher,
      );
    });

    test('SubmitReflection runs analysis and pattern detection', () async {
      final journeyId = JourneyId.generate();
      final reflectionId = ReflectionId.generate();

      final journeyResult = await lifeJourney.application.createJourney(
        userId: userId,
        request: CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Grow with courage every day'),
        ),
      );
      expect(journeyResult.isSuccess, isTrue);

      final reflectionResult = await lifeJourney.application.createReflection(
        userId: userId,
        request: CreateReflectionRequest(
          reflectionId: reflectionId,
          journeyId: journeyId,
        ),
      );
      expect(reflectionResult.isSuccess, isTrue);

      await lifeJourney.application.addReflectionResponse(
        userId: userId,
        reflectionId: reflectionId,
        response: const EmojiResponse(emotion: ReflectionEmotion.proud),
      );

      final submit = await lifeJourney.application.submitReflection(
        userId: userId,
        request: SubmitReflectionRequest(reflectionId: reflectionId),
      );
      expect(submit.isSuccess, isTrue, reason: submit.isFailure
          ? submit.fold(onSuccess: (_) => '', onFailure: (f) => f.message)
          : null);

      late final SubmitReflectionResultDto dto;
      submit.fold(
        onSuccess: (v) => dto = v,
        onFailure: (f) => fail(f.message),
      );
      expect(dto.reflection.submittedAt, isNotNull);
      expect(dto.reflection.evidenceCount, greaterThan(0));

      final events = await eventStore.readAll();
      final types = events.map((e) => e.event.runtimeType.toString()).toList();
      expect(types, contains('ReflectionSubmitted'));
      expect(types, contains('BehavioralEvidenceDetected'));
      expect(types, contains('InsightsGenerated'));
    });

    test('duplicate submit fails with already submitted', () async {
      final journeyId = JourneyId.generate();
      final reflectionId = ReflectionId.generate();

      await lifeJourney.application.createJourney(
        userId: userId,
        request: CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Grow with courage every day'),
        ),
      );
      await lifeJourney.application.createReflection(
        userId: userId,
        request: CreateReflectionRequest(
          reflectionId: reflectionId,
          journeyId: journeyId,
        ),
      );
      await lifeJourney.application.addReflectionResponse(
        userId: userId,
        reflectionId: reflectionId,
        response: const EmojiResponse(emotion: ReflectionEmotion.grateful),
      );
      final first = await lifeJourney.application.submitReflection(
        userId: userId,
        request: SubmitReflectionRequest(reflectionId: reflectionId),
      );
      expect(first.isSuccess, isTrue);

      final second = await lifeJourney.application.submitReflection(
        userId: userId,
        request: SubmitReflectionRequest(reflectionId: reflectionId),
      );
      expect(second.isFailure, isTrue);
      second.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (f) =>
            expect(f.message.toLowerCase(), contains('already')),
      );
    });
  });

  group('H.2 HTTP API (in-memory)', () {
    late LifeJourneyComponents lifeJourney;
    late http.Client client;
    late Uri base;
    final principal = AuthenticatedPrincipal(
      userId: UserId('00000000-0000-4000-8000-0000000000aa'),
      displayName: 'API User',
    );

    setUp(() async {
      final eventStore = InMemoryEventStore();
      final dispatcher = InMemoryEventDispatcher();
      final eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );
      lifeJourney = LifeJourneyModule.composeInMemory(
        eventBus: eventBus,
        eventDispatcher: dispatcher,
      );
      final handler = lifeJourneyTestHandler(
        components: lifeJourney,
        principal: principal,
      );
      final server = await shelf_io.serve(handler, 'localhost', 0);
      base = Uri.parse('http://localhost:${server.port}');
      client = http.Client();
      addTearDown(() async {
        client.close();
        await server.close(force: true);
      });
    });

    Future<http.Response> post(
      String path,
      Map<String, Object?> body, {
      Map<String, String>? headers,
    }) {
      return client.post(
        base.replace(path: path),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer test-token',
          ...?headers,
        },
        body: jsonEncode(body),
      );
    }

    Future<http.Response> get(String path) {
      return client.get(
        base.replace(path: path),
        headers: {'authorization': 'Bearer test-token'},
      );
    }

    test('vertical HTTP → submit → understanding', () async {
      final journey = await post('/v1/journeys', {
        'vision': 'Become more consistent',
      });
      expect(journey.statusCode, 201, reason: journey.body);
      final journeyId =
          (jsonDecode(journey.body) as Map)['journeyId'] as String;

      final reflection = await post('/v1/reflections', {
        'journeyId': journeyId,
      });
      expect(reflection.statusCode, 201, reason: reflection.body);
      final reflectionId =
          (jsonDecode(reflection.body) as Map)['reflectionId'] as String;

      final response = await post('/v1/reflections/$reflectionId/responses', {
        'type': 'emoji',
        'emotion': 'hopeful',
      });
      expect(response.statusCode, 200, reason: response.body);

      final submit = await post(
        '/v1/reflections/$reflectionId/submit',
        {},
        headers: {'Idempotency-Key': 'sub-1'},
      );
      expect(submit.statusCode, 200, reason: submit.body);
      final body = jsonDecode(submit.body) as Map;
      expect(body['reflection'], isNotNull);
      expect(body['understanding'], isNotNull);

      final replay = await post(
        '/v1/reflections/$reflectionId/submit',
        {},
        headers: {'Idempotency-Key': 'sub-1'},
      );
      expect(replay.statusCode, 200);
      expect(replay.headers['x-idempotent-replay'], 'true');

      final understanding = await get('/v1/understanding/current');
      expect(understanding.statusCode, 200);
      expect((jsonDecode(understanding.body) as Map)['journeyId'], journeyId);

      final current = await get('/v1/journeys/current');
      expect(current.statusCode, 200);
    });

    test('malformed reflection response is rejected', () async {
      final journey = await post('/v1/journeys', {
        'vision': 'Become more consistent',
      });
      final journeyId =
          (jsonDecode(journey.body) as Map)['journeyId'] as String;
      final reflection = await post('/v1/reflections', {
        'journeyId': journeyId,
      });
      final reflectionId =
          (jsonDecode(reflection.body) as Map)['reflectionId'] as String;

      final bad = await post('/v1/reflections/$reflectionId/responses', {
        'type': 'emoji',
        'emotion': 'not-a-real-emotion',
      });
      expect(bad.statusCode, 400);
    });
  });
}
