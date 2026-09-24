import 'dart:convert';
import 'dart:io';

import 'package:eh_platform/eh_platform.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/journal_response.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_reflection_repository.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

import 'support/platform_paths.dart';

Handler _handler({
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

({
  LifeJourneyComponents lifeJourney,
  ExperienceComponents experience,
  HeroStoryComponents heroStory,
}) _composeLive({
  required StoryCandidateSource candidateSource,
  DiscoverableStoryCandidateProjection? projection,
}) {
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
  final heroStory = HeroStoryModule.compose(
    candidateSource: candidateSource,
    projection: projection,
  );
  final experience = ExperienceModule.compose(
    transactions: lifeJourney.transactions,
    journeyRepository: lifeJourney.journeyRepository,
    discoverySignalPort: discovery.adaptiveDiscoverySignalPort,
    storyCandidatePort: heroStory.storyCandidatePort,
  );
  return (
    lifeJourney: lifeJourney,
    experience: experience,
    heroStory: heroStory,
  );
}

Future<void> _submitAnalyzedReflection({
  required LifeJourneyComponents lifeJourney,
  required UserId userId,
  required JourneyId journeyId,
  required ReflectionId reflectionId,
}) async {
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
    response: const JournalResponse(response: 'I am finding my direction'),
  );
  await lifeJourney.application.submitReflection(
    userId: userId,
    request: SubmitReflectionRequest(reflectionId: reflectionId),
  );
}

StoryCandidateEligibilityFacts _liveFacts({
  required String storyId,
  required String title,
  required List<String> themeIds,
  DateTime? updatedAt,
  String lifecycleStatus = 'published',
  String storyVisibility = 'public',
  String heroStatus = 'active',
  String heroVisibility = 'public',
  bool hasAuthoritativeRepresentation = true,
  bool hasProvisionalNarrative = false,
}) {
  return StoryCandidateEligibilityFacts(
    storyId: storyId,
    heroId: 'live-hero-a',
    title: title,
    themeIds: themeIds,
    updatedAt: updatedAt ?? DateTime.utc(2026, 6, 1),
    lifecycleStatus: lifecycleStatus,
    storyVisibility: storyVisibility,
    hasProvisionalNarrative: hasProvisionalNarrative,
    hasAuthoritativeRepresentation: hasAuthoritativeRepresentation,
    heroStatus: heroStatus,
    heroVisibility: heroVisibility,
  );
}

void main() {
  group('J.2 Slice 4 live projection → Today Experience', () {
    late InMemoryDiscoverableStoryCandidateProjection projection;
    late ProjectDiscoverableStoryCandidateUseCase project;
    late LifeJourneyComponents lifeJourney;
    late ExperienceComponents experience;
    final userId = UserId('00000000-0000-4000-8000-0000000000s4');

    setUp(() {
      projection = InMemoryDiscoverableStoryCandidateProjection();
      project = ProjectDiscoverableStoryCandidateUseCase(
        projection: projection,
      );
      final composed = _composeLive(
        candidateSource: projection,
        projection: projection,
      );
      lifeJourney = composed.lifeJourney;
      experience = composed.experience;
    });

    test(
      'Case A: relevant live Story → adaptive Story experience',
      () async {
        await project.execute(
          _liveFacts(
            storyId: 'live-story-finding-direction',
            title: 'Live Finding Direction',
            themeIds: const ['discovery', 'purpose'],
          ),
        );

        final journeyId = JourneyId('j-slice4-a');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow with discovery'),
          ),
        );
        await _submitAnalyzedReflection(
          lifeJourney: lifeJourney,
          userId: userId,
          journeyId: journeyId,
          reflectionId: ReflectionId('r-slice4-a'),
        );

        final dto = (await experience.application.getTodayExperience(
          userId: userId,
        ))
            .getOrThrow();

        expect(dto.experienceType, 'story');
        expect(
          dto.experienceId,
          'adaptive-story-live-story-finding-direction',
        );
        expect(dto.title, 'Live Finding Direction');
        expect(dto.target!['storyId'], 'live-story-finding-direction');
      },
    );

    test(
      'Case B: empty live projection → default reflection',
      () async {
        final journeyId = JourneyId('j-slice4-b');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );
        await _submitAnalyzedReflection(
          lifeJourney: lifeJourney,
          userId: userId,
          journeyId: journeyId,
          reflectionId: ReflectionId('r-slice4-b'),
        );

        final dto = (await experience.application.getTodayExperience(
          userId: userId,
        ))
            .getOrThrow();
        expect(dto.experienceType, 'reflection');
        expect(dto.experienceId, 'default-reflection');
      },
    );

    test(
      'Case B2: no relevant live Story → reflection experience',
      () async {
        await project.execute(
          _liveFacts(
            storyId: 'live-story-leadership',
            title: 'Leading',
            themeIds: const ['leadership'],
          ),
        );

        final journeyId = JourneyId('j-slice4-b2');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );

        final reflection = Reflection(
          id: ReflectionId('r-slice4-b2'),
          journeyId: journeyId,
          createdAt: DateTime.utc(2026, 3, 1),
          submittedAt: DateTime.utc(2026, 3, 2),
          narrativeThemes: const [NarrativeThemeId('love')],
        );
        await (lifeJourney.reflectionRepository
                as OwnedInMemoryReflectionRepository)
            .saveForUser(reflection, userId);

        final dto = (await experience.application.getTodayExperience(
          userId: userId,
        ))
            .getOrThrow();
        expect(dto.experienceId, 'default-reflection');
      },
    );

    test(
      'Case C: multiple live overlaps → deterministic winner',
      () async {
        await project.execute(
          _liveFacts(
            storyId: 'live-story-courage-alone',
            title: 'Alone',
            themeIds: const ['courage'],
            updatedAt: DateTime.utc(2026, 1, 11),
          ),
        );
        await project.execute(
          _liveFacts(
            storyId: 'live-story-rising-again',
            title: 'Rising Again',
            themeIds: const ['courage', 'perseverance'],
            updatedAt: DateTime.utc(2026, 1, 10),
          ),
        );

        final journeyId = JourneyId('j-slice4-c');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );

        final reflection = Reflection(
          id: ReflectionId('r-slice4-c'),
          journeyId: journeyId,
          createdAt: DateTime.utc(2026, 3, 1),
          submittedAt: DateTime.utc(2026, 3, 2),
          narrativeThemes: const [
            NarrativeThemeId('courage'),
            NarrativeThemeId('perseverance'),
          ],
        );
        await (lifeJourney.reflectionRepository
                as OwnedInMemoryReflectionRepository)
            .saveForUser(reflection, userId);

        final first = (await experience.application.getTodayExperience(
          userId: userId,
        ))
            .getOrThrow();
        final second = (await experience.application.getTodayExperience(
          userId: userId,
        ))
            .getOrThrow();

        expect(first.experienceId, 'adaptive-story-live-story-rising-again');
        expect(second.experienceId, first.experienceId);
      },
    );

    test(
      'ineligible projection removal → fail-closed reflection',
      () async {
        await project.execute(
          _liveFacts(
            storyId: 'live-story-finding-direction',
            title: 'Live Finding Direction',
            themeIds: const ['discovery'],
          ),
        );

        final journeyId = JourneyId('j-slice4-remove');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );
        await _submitAnalyzedReflection(
          lifeJourney: lifeJourney,
          userId: userId,
          journeyId: journeyId,
          reflectionId: ReflectionId('r-slice4-remove'),
        );

        var dto = (await experience.application.getTodayExperience(
          userId: userId,
        ))
            .getOrThrow();
        expect(dto.experienceType, 'story');

        await project.execute(
          _liveFacts(
            storyId: 'live-story-finding-direction',
            title: 'Live Finding Direction',
            themeIds: const ['discovery'],
            lifecycleStatus: 'archived',
          ),
        );

        dto = (await experience.application.getTodayExperience(
          userId: userId,
        ))
            .getOrThrow();
        expect(dto.experienceId, 'default-reflection');
      },
    );

    test('Case A over HTTP with live projection', () async {
      await project.execute(
        _liveFacts(
          storyId: 'live-story-finding-direction',
          title: 'Live Finding Direction',
          themeIds: const ['discovery', 'purpose'],
        ),
      );

      final principal = AuthenticatedPrincipal(
        userId: userId,
        displayName: 'Slice4',
      );
      final journeyId = JourneyId('j-http-s4-a');
      await lifeJourney.application.createJourney(
        userId: userId,
        request: CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Grow'),
        ),
      );
      await _submitAnalyzedReflection(
        lifeJourney: lifeJourney,
        userId: userId,
        journeyId: journeyId,
        reflectionId: ReflectionId('r-http-s4-a'),
      );

      final handler = _handler(
        lifeJourney: lifeJourney,
        experience: experience,
        principal: principal,
      );
      final server = await shelf_io.serve(handler, '127.0.0.1', 0);
      addTearDown(() => server.close(force: true));

      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:${server.port}/v1/experiences/today',
        ),
      );
      expect(response.statusCode, 200);
      expect(response.body, contains('"experienceType":"story"'));
      expect(
        response.body,
        contains(
          '"experienceId":"adaptive-story-live-story-finding-direction"',
        ),
      );
      expect(response.body, isNot(contains('seed-story-')));
    });
  });

  group('J.2 Slice 4 PostgreSQL candidate projection', () {
    final dbUrl = Platform.environment['EH_DATABASE_URL'] ??
        'postgres://eh:eh_dev@127.0.0.1:5432/eh_platform';
    late PlatformDatabase database;
    late PostgresStoryCandidateSource source;
    late ProjectDiscoverableStoryCandidateUseCase project;
    late String root;

    setUpAll(() async {
      root = ehPlatformRoot();
      database = await PlatformDatabase.connect(dbUrl);
      await MigrationRunner(
        database: database,
        migrationsDirectory: '$root/migrations',
      ).applyPending();
    });

    setUp(() async {
      source = PostgresStoryCandidateSource(database);
      project = ProjectDiscoverableStoryCandidateUseCase(projection: source);
      await database.connection.execute(
        'DELETE FROM discoverable_story_candidates',
      );
    });

    tearDownAll(() async {
      await database.close();
    });

    test('migration creates discoverable_story_candidates', () async {
      final rows = await database.connection.execute(
        r'''
SELECT 1 FROM information_schema.tables
WHERE table_name = 'discoverable_story_candidates'
''',
      );
      expect(rows, isNotEmpty);
    });

    test('postgres upsert + listCandidates round-trip', () async {
      await project.execute(
        _liveFacts(
          storyId: 'pg-story-1',
          title: 'PG Story',
          themeIds: const ['discovery', 'courage'],
        ),
      );
      final listed = await source.listCandidates();
      expect(listed, hasLength(1));
      expect(listed.single.storyId, 'pg-story-1');
      expect(listed.single.themeIds, ['courage', 'discovery']);
      expect(await source.exists('pg-story-1'), isTrue);
    });

    test('postgres eligibility removal deletes row', () async {
      await project.execute(
        _liveFacts(
          storyId: 'pg-story-2',
          title: 'PG Story 2',
          themeIds: const ['courage'],
        ),
      );
      await project.execute(
        _liveFacts(
          storyId: 'pg-story-2',
          title: 'PG Story 2',
          themeIds: const ['courage'],
          storyVisibility: 'private',
        ),
      );
      expect(await source.exists('pg-story-2'), isFalse);
      expect(await source.listCandidates(), isEmpty);
    });

    test(
      'composePostgres + bootstrap path does not use architectural seed',
      () async {
        final heroStory = HeroStoryModule.composePostgres(database: database);
        expect(heroStory.candidateSource, isA<PostgresStoryCandidateSource>());

        await project.execute(
          _liveFacts(
            storyId: 'pg-bootstrap-story',
            title: 'Bootstrap Live',
            themeIds: const ['discovery'],
          ),
        );

        final result = await heroStory.storyCandidatePort.findRelevant(
          AdaptiveDiscoverySignals(
            narrativeThemeIds: const ['discovery'],
          ),
        );
        expect(result.single.storyId, 'pg-bootstrap-story');
        expect(result.single.title, isNot(contains('[Seed]')));
      },
    );

    test(
      'PlatformComposition bootstrap wires live Postgres candidate source',
      () async {
        final config = PlatformConfig.testing(
          databaseUrl: dbUrl,
          environment: 'test',
          devAuthToken: 'pg-s4-token',
          devUserId: '00000000-0000-4000-8000-0000000000c4',
          devUserDisplayName: 'Slice4 PG',
        );
        final composition = await PlatformComposition.bootstrap(
          config: config,
          migrationsDirectory: '$root/migrations',
        );
        addTearDown(composition.close);

        expect(
          composition.heroStory.candidateSource,
          isA<PostgresStoryCandidateSource>(),
        );

        // Clear + project a live row, then exercise HTTP Today Experience.
        await composition.database.connection.execute(
          'DELETE FROM discoverable_story_candidates',
        );
        await composition.database.connection.execute(
          r'DELETE FROM reflections WHERE user_id = $1::uuid',
          parameters: [config.devUserId],
        );
        await composition.database.connection.execute(
          r'DELETE FROM journeys WHERE user_id = $1::uuid',
          parameters: [config.devUserId],
        );

        final liveProject = ProjectDiscoverableStoryCandidateUseCase(
          projection: composition.heroStory.projection!,
        );
        await liveProject.execute(
          _liveFacts(
            storyId: 'pg-http-live-story',
            title: 'HTTP Live Story',
            themeIds: const ['discovery', 'purpose'],
          ),
        );

        final server =
            await shelf_io.serve(composition.handler, 'localhost', 0);
        addTearDown(() => server.close(force: true));
        final base = Uri.parse('http://localhost:${server.port}');
        final client = http.Client();
        addTearDown(client.close);

        Future<http.Response> post(String path, Map<String, Object?> body) {
          return client.post(
            base.replace(path: path),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer pg-s4-token',
              'Idempotency-Key': 's4-$path-${body.hashCode}',
            },
            body: jsonEncode(body),
          );
        }

        final journey = await post('/v1/journeys', {
          'vision': 'Live candidate discovery',
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

        final response = await post(
          '/v1/reflections/$reflectionId/responses',
          {'type': 'emoji', 'emotion': 'calm'},
        );
        expect(response.statusCode, 200, reason: response.body);

        final submit = await post(
          '/v1/reflections/$reflectionId/submit',
          {},
        );
        expect(submit.statusCode, 200, reason: submit.body);

        final today = await client.get(
          base.replace(path: '/v1/experiences/today'),
          headers: {'authorization': 'Bearer pg-s4-token'},
        );
        expect(today.statusCode, 200, reason: today.body);
        expect(today.body, contains('"experienceType":"story"'));
        expect(
          today.body,
          contains('"experienceId":"adaptive-story-pg-http-live-story"'),
        );
        expect(today.body, isNot(contains('seed-story-')));
      },
    );
  });
}
