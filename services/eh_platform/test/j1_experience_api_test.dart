import 'dart:convert';

import 'package:eh_platform/eh_platform.dart';
import 'package:eh_platform/src/api/middleware/auth_middleware.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/detect_pattern_use_case.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:eh_platform/src/life_journey/domain/enums/behavioral_evidence_type.dart';
import 'package:eh_platform/src/life_journey/domain/enums/reflection_emotion.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/rules/consistency_pattern_rule.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/evidence_source.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/strength.dart';
import 'package:eh_platform/src/life_journey/infrastructure/services/behavioral_analysis/rule_based_pattern_detector.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

Handler j1TestHandler({
  required LifeJourneyComponents lifeJourney,
  required ExperienceComponents experience,
  required AuthenticatedPrincipal principal,
}) {
  final modules = Cascade()
      .add(lifeJourney.handler)
      .add(experience.handler)
      .handler;

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
      .addHandler(modules);
}

/// Seeds ≥3 discipline evidence on submitted reflections, then runs H.2
/// [DefaultDetectPatternUseCase] — the same path BehavioralEvidenceDetected
/// reactors use — so Today's Experience consumes updated Journey understanding.
Future<void> seedConsistencyViaH2({
  required LifeJourneyComponents lifeJourney,
  required UserId userId,
  required JourneyId journeyId,
}) async {
  final now = DateTime.utc(2026, 2, 1);
  for (var i = 0; i < 3; i++) {
    final reflectionId = ReflectionId('r-h2-$i-${journeyId.value}');
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
      response: const EmojiResponse(emotion: ReflectionEmotion.proud),
    );
    await lifeJourney.application.submitReflection(
      userId: userId,
      request: SubmitReflectionRequest(reflectionId: reflectionId),
    );

    // Simulate Insight/Evidence analysis producing discipline observations
    // (emoji analyzer does not guarantee discipline — known H.2 gap).
    final reflection =
        await lifeJourney.reflectionRepository.findById(reflectionId);
    reflection!.addBehavioralEvidence([
      BehavioralEvidence(
        type: BehavioralEvidenceType.discipline,
        source: ReflectionEvidenceSource(reflectionId: reflectionId),
        strength: const Strength(0.9),
        observedAt: now.add(Duration(hours: i)),
      ),
    ]);
    await lifeJourney.reflectionRepository.save(reflection);
  }

  final detect = DefaultDetectPatternUseCase(
    journeyRepository: lifeJourney.journeyRepository,
    reflectionRepository: lifeJourney.reflectionRepository,
    detector: RuleBasedPatternDetector(rules: [ConsistencyPatternRule()]),
    eventBus: lifeJourney.application.eventBus,
  );
  final patterns = await detect.execute(journeyId);
  expect(patterns.isSuccess, isTrue, reason: 'H.2 DetectPatternUseCase failed');
  final detected = patterns.getOrThrow();
  expect(detected.any((p) => p.type.name == 'consistency'), isTrue);
}

void main() {
  group('J.1 GetTodayExperience application', () {
    late LifeJourneyComponents lifeJourney;
    late ExperienceComponents experience;
    final userId = UserId('00000000-0000-4000-8000-000000000001');

    setUp(() {
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
      final discovery = DiscoveryModule.compose(
        reflectionRepository: lifeJourney.reflectionRepository,
      );
      experience = ExperienceModule.compose(
        transactions: lifeJourney.transactions,
        journeyRepository: lifeJourney.journeyRepository,
        discoverySignalPort: discovery.adaptiveDiscoverySignalPort,
      );
    });

    test('404 when authenticated principal has no Journey', () async {
      final result = await experience.application.getTodayExperience(
        userId: userId,
      );
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (f) => expect(f.code, 'not_found'),
      );
    });

    test('default-reflection for new Journey', () async {
      await lifeJourney.application.createJourney(
        userId: userId,
        request: CreateJourneyRequest(
          journeyId: JourneyId('j-default'),
          vision: JourneyVision('Grow with courage'),
        ),
      );

      final result = await experience.application.getTodayExperience(
        userId: userId,
      );
      final dto = result.getOrThrow();
      expect(dto.experienceId, 'default-reflection');
      expect(dto.experienceType, 'reflection');
      expect(dto.journeyId, 'j-default');
      expect(dto.action, 'begin');
      expect(dto.explanation.sources, isEmpty);
    });

    test(
      'H.2 DetectPatternUseCase → consistency → consistency-next-step',
      () async {
        final journeyId = JourneyId('j-consistency');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow with courage'),
          ),
        );

        final before = await experience.application.getTodayExperience(
          userId: userId,
        );
        expect(before.getOrThrow().experienceId, 'default-reflection');

        await seedConsistencyViaH2(
          lifeJourney: lifeJourney,
          userId: userId,
          journeyId: journeyId,
        );

        final result = await experience.application.getTodayExperience(
          userId: userId,
        );
        final dto = result.getOrThrow();
        expect(dto.experienceId, 'consistency-next-step');
        expect(dto.title, 'Keep Showing Up');
        expect(dto.rationale, isNotNull);
        expect(dto.explanation.sources.first.value, 'consistency');
      },
    );
  });

  group('J.1 GET /v1/experiences/today API', () {
    late http.Client client;
    late Uri base;
    late LifeJourneyComponents lifeJourney;
    late ExperienceComponents experience;
    final userId = UserId('00000000-0000-4000-8000-000000000002');
    final principal = AuthenticatedPrincipal(
      userId: userId,
      displayName: 'J1 Tester',
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
      final discovery = DiscoveryModule.compose(
        reflectionRepository: lifeJourney.reflectionRepository,
      );
      experience = ExperienceModule.compose(
        transactions: lifeJourney.transactions,
        journeyRepository: lifeJourney.journeyRepository,
        discoverySignalPort: discovery.adaptiveDiscoverySignalPort,
      );

      final handler = j1TestHandler(
        lifeJourney: lifeJourney,
        experience: experience,
        principal: principal,
      );
      final server = await shelf_io.serve(handler, '127.0.0.1', 0);
      base = Uri.parse('http://127.0.0.1:${server.port}');
      client = http.Client();
      addTearDown(() async {
        client.close();
        await server.close(force: true);
      });
    });

    Future<http.Response> get(String path) {
      return client.get(base.replace(path: path));
    }

    Future<http.Response> post(String path, Map<String, Object?> body) {
      return client.post(
        base.replace(path: path),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      );
    }

    test('404 without current Journey', () async {
      final response = await get('/v1/experiences/today');
      expect(response.statusCode, 404);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['error']['code'], 'not_found');
    });

    test('200 default-reflection after Journey create', () async {
      final created = await post('/v1/journeys', {
        'vision': 'Grow',
        'journeyId': 'j-api-default',
      });
      expect(created.statusCode, 201);

      final response = await get('/v1/experiences/today');
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['experienceId'], 'default-reflection');
      expect(body['experienceType'], 'reflection');
      expect(body['journeyId'], 'j-api-default');
      expect(body['action'], 'begin');
      expect(body.containsKey('explanation'), isTrue);
      expect(body.containsKey('target'), isTrue);
    });

    test('Slice 4: Reflection → H.2 DetectPattern → Today experience', () async {
      await post('/v1/journeys', {
        'vision': 'Grow with discipline',
        'journeyId': 'j-slice4',
      });

      final before = await get('/v1/experiences/today');
      expect(jsonDecode(before.body)['experienceId'], 'default-reflection');

      await seedConsistencyViaH2(
        lifeJourney: lifeJourney,
        userId: userId,
        journeyId: JourneyId('j-slice4'),
      );

      final after = await get('/v1/experiences/today');
      expect(after.statusCode, 200);
      final body = jsonDecode(after.body) as Map<String, dynamic>;
      expect(body['experienceId'], 'consistency-next-step');
      expect(body['journeyId'], 'j-slice4');
      final sources = (body['explanation'] as Map)['sources'] as List;
      expect(
        sources.any(
          (s) =>
              s is Map &&
              s['kind'] == 'behavior_pattern' &&
              s['value'] == 'consistency',
        ),
        isTrue,
      );

      // Understanding remains separate from recommendation.
      final understanding = await get('/v1/understanding/current');
      expect(understanding.statusCode, 200);
      final uBody = jsonDecode(understanding.body) as Map<String, dynamic>;
      expect(uBody['patterns'], isNotEmpty);
      expect(uBody.containsKey('experienceId'), isFalse);
    });

    test('does not expose BehaviorPattern domain fields', () async {
      await post('/v1/journeys', {
        'vision': 'Grow',
        'journeyId': 'j-dto',
      });
      final response = await get('/v1/experiences/today');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body.containsKey('behaviorPatterns'), isFalse);
      expect(body.containsKey('supportingEvidence'), isFalse);
      expect(body.containsKey('activeQuestIds'), isFalse);
    });
  });

  group('J.1 auth boundary', () {
    test('GET /v1/experiences/today requires authenticated principal', () async {
      final eventStore = InMemoryEventStore();
      final dispatcher = InMemoryEventDispatcher();
      final eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );
      final lifeJourney = LifeJourneyModule.composeInMemory(
        eventBus: eventBus,
        eventDispatcher: dispatcher,
      );
      final discovery = DiscoveryModule.compose(
        reflectionRepository: lifeJourney.reflectionRepository,
      );
      final experience = ExperienceModule.compose(
        transactions: lifeJourney.transactions,
        journeyRepository: lifeJourney.journeyRepository,
        discoverySignalPort: discovery.adaptiveDiscoverySignalPort,
      );

      final handler = const Pipeline()
          .addMiddleware(correlationMiddleware())
          .addMiddleware(requireAuth())
          .addHandler(experience.handler);

      final server = await shelf_io.serve(handler, '127.0.0.1', 0);
      final client = http.Client();
      addTearDown(() async {
        client.close();
        await server.close(force: true);
      });

      final response = await client.get(
        Uri.parse('http://127.0.0.1:${server.port}/v1/experiences/today'),
      );
      expect(response.statusCode, 401);
    });
  });
}
