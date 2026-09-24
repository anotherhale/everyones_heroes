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
import 'package:eh_platform/src/shared_kernel/exceptions/validation_exception.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

Handler _j2Handler({
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

/// Compose Life Journey + Discovery + Hero & Story + Experience.
///
/// Slice 3 regression tests still use the architectural seed as an **explicit**
/// fixture. Production composition uses the live Postgres projection (Slice 4).
({
  LifeJourneyComponents lifeJourney,
  ExperienceComponents experience,
  HeroStoryComponents heroStory,
}) _composeWithCandidates({
  StoryCandidateSource? candidateSource,
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
    candidateSource:
        candidateSource ?? SeededStoryCandidateCatalog.architecturalSeed(),
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

void main() {
  group('StoryCandidateRecord validation (Case D)', () {
    test('unknown theme ID fails at construction (load-time)', () {
      expect(
        () => StoryCandidateRecord(
          storyId: 'bad',
          heroId: 'hero',
          title: 'Bad',
          themeIds: const ['courage', 'not-a-real-theme'],
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('empty theme list fails validation', () {
      expect(
        () => StoryCandidateRecord(
          storyId: 'bad',
          heroId: 'hero',
          title: 'Bad',
          themeIds: const [],
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('catalog theme IDs are accepted and sorted uniquely', () {
      final record = StoryCandidateRecord(
        storyId: 'ok',
        heroId: 'hero',
        title: 'Ok',
        themeIds: const ['purpose', 'courage', 'courage'],
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      expect(record.themeIds, ['courage', 'purpose']);
      for (final id in record.themeIds) {
        expect(NarrativeThemeReferenceIds.containsValue(id), isTrue);
      }
    });

    test('seed catalog rejects records that somehow bypass validation', () {
      // Construction of StoryCandidateRecord already fails; this asserts the
      // catalog factory itself only accepts catalog-valid architectural seed.
      final seed = SeededStoryCandidateCatalog.architecturalSeed();
      expect(seed.records, isNotEmpty);
      for (final record in seed.records) {
        for (final themeId in record.themeIds) {
          expect(NarrativeThemeReferenceIds.containsValue(themeId), isTrue);
        }
      }
    });
  });

  group('DeterministicStoryRelevanceRanker (Case C)', () {
    const ranker = DeterministicStoryRelevanceRanker();

    test('higher theme overlap wins; selection is deterministic', () {
      final records = [
        StoryCandidateRecord(
          storyId: 'seed-story-courage-alone',
          heroId: 'h1',
          title: 'One Act',
          themeIds: const ['courage'],
          updatedAt: DateTime.utc(2026, 1, 11),
        ),
        StoryCandidateRecord(
          storyId: 'seed-story-rising-again',
          heroId: 'h1',
          title: 'Rising',
          themeIds: const ['courage', 'perseverance'],
          updatedAt: DateTime.utc(2026, 1, 10),
        ),
      ];

      final signals = AdaptiveDiscoverySignals(
        narrativeThemeIds: const ['courage', 'perseverance'],
      );

      final a = ranker.rank(records: records, signals: signals);
      final b = ranker.rank(records: records.reversed.toList(), signals: signals);

      expect(a.first.storyId, 'seed-story-rising-again');
      expect(a.first.themeOverlapCount, 2);
      expect(a.map((c) => c.storyId).toList(), b.map((c) => c.storyId).toList());
    });

    test('equal overlap ties break by updatedAt desc then storyId asc', () {
      final records = [
        StoryCandidateRecord(
          storyId: 'story-b',
          heroId: 'h1',
          title: 'B',
          themeIds: const ['courage'],
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        StoryCandidateRecord(
          storyId: 'story-a',
          heroId: 'h1',
          title: 'A',
          themeIds: const ['courage'],
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        StoryCandidateRecord(
          storyId: 'story-c',
          heroId: 'h1',
          title: 'C',
          themeIds: const ['courage'],
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ];

      final ranked = ranker.rank(
        records: records,
        signals: AdaptiveDiscoverySignals(
          narrativeThemeIds: const ['courage'],
        ),
      );

      expect(
        ranked.map((c) => c.storyId).toList(),
        ['story-c', 'story-a', 'story-b'],
      );
    });

    test(
      'recent theme beats older union theme despite newer Story updatedAt',
      () {
        final ranked = ranker.rank(
          records: [
            StoryCandidateRecord(
              storyId: 'courage-newer',
              heroId: 'h1',
              title: 'Courage newer',
              themeIds: const ['courage'],
              updatedAt: DateTime.utc(2026, 3, 1),
            ),
            StoryCandidateRecord(
              storyId: 'service-older',
              heroId: 'h1',
              title: 'Service older',
              themeIds: const ['service'],
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          ],
          signals: AdaptiveDiscoverySignals(
            narrativeThemeIds: const ['courage', 'service'],
            themeLastExpressedAt: {
              'courage': DateTime.utc(2026, 2, 1),
              'service': DateTime.utc(2026, 2, 2),
            },
          ),
        );

        expect(
          ranked.map((c) => c.storyId).toList(),
          ['service-older', 'courage-newer'],
        );
        expect(
          ranked.first.updatedAt.isBefore(ranked.last.updatedAt),
          isTrue,
        );
      },
    );

    test(
      'historical themes remain; ranking prefers most recent matched theme',
      () {
        final ranked = ranker.rank(
          records: [
            StoryCandidateRecord(
              storyId: 'courage-story',
              heroId: 'h1',
              title: 'Courage',
              themeIds: const ['courage'],
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
            StoryCandidateRecord(
              storyId: 'service-story',
              heroId: 'h1',
              title: 'Service',
              themeIds: const ['service'],
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          ],
          signals: AdaptiveDiscoverySignals(
            narrativeThemeIds: const ['courage', 'service'],
            themeLastExpressedAt: {
              'courage': DateTime.utc(2026, 1, 10),
              'service': DateTime.utc(2026, 1, 20),
            },
          ),
        );

        expect(
          ranked.map((c) => c.storyId).toSet(),
          {'courage-story', 'service-story'},
        );
        expect(ranked.first.storyId, 'service-story');
      },
    );

    test(
      'equivalent recent-theme candidates tie-break by storyId when timestamps match',
      () {
        final expressed = DateTime.utc(2026, 2, 1);
        final updated = DateTime.utc(2026, 1, 15);
        final signals = AdaptiveDiscoverySignals(
          narrativeThemeIds: const ['service'],
          themeLastExpressedAt: {'service': expressed},
        );

        final ranked = ranker.rank(
          records: [
            StoryCandidateRecord(
              storyId: 'story-b',
              heroId: 'h1',
              title: 'B',
              themeIds: const ['service'],
              updatedAt: updated,
            ),
            StoryCandidateRecord(
              storyId: 'story-a',
              heroId: 'h1',
              title: 'A',
              themeIds: const ['service'],
              updatedAt: updated,
            ),
          ],
          signals: signals,
        );

        expect(ranked.map((c) => c.storyId).toList(), ['story-a', 'story-b']);

        final again = ranker.rank(
          records: [
            StoryCandidateRecord(
              storyId: 'story-a',
              heroId: 'h1',
              title: 'A',
              themeIds: const ['service'],
              updatedAt: updated,
            ),
            StoryCandidateRecord(
              storyId: 'story-b',
              heroId: 'h1',
              title: 'B',
              themeIds: const ['service'],
              updatedAt: updated,
            ),
          ].reversed.toList(),
          signals: signals,
        );
        expect(again.map((c) => c.storyId).toList(), ['story-a', 'story-b']);
      },
    );

    test('no theme overlap yields empty (fail-closed input to composer)', () {
      final ranked = ranker.rank(
        records: SeededStoryCandidateCatalog.architecturalSeed().records,
        signals: AdaptiveDiscoverySignals(
          narrativeThemeIds: const ['love'],
        ),
      );
      expect(ranked, isEmpty);
    });
  });

  group('DiscoverableStoryCandidateAdapter', () {
    test('no signal themes → empty candidates (patterns alone insufficient)',
        () async {
      final heroStory = HeroStoryModule.compose(
        candidateSource: SeededStoryCandidateCatalog.architecturalSeed(),
      );
      final result = await heroStory.storyCandidatePort.findRelevant(
        AdaptiveDiscoverySignals(),
      );
      expect(result, isEmpty);
    });

    test('matching themes return ranked DiscoverableStoryCandidate list',
        () async {
      final heroStory = HeroStoryModule.compose(
        candidateSource: SeededStoryCandidateCatalog.architecturalSeed(),
      );
      final result = await heroStory.storyCandidatePort.findRelevant(
        AdaptiveDiscoverySignals(
          narrativeThemeIds: const ['discovery'],
        ),
      );
      expect(result, isNotEmpty);
      expect(result.first.storyId, 'seed-story-finding-direction');
      expect(result.first.themeOverlapCount, greaterThan(0));
      expect(result.first.matchedThemeIds, contains('discovery'));
    });

    test('HeroStoryModule.compose() defaults to empty (not architectural seed)',
        () async {
      final heroStory = HeroStoryModule.compose();
      final result = await heroStory.storyCandidatePort.findRelevant(
        AdaptiveDiscoverySignals(
          narrativeThemeIds: const ['discovery'],
        ),
      );
      expect(result, isEmpty);
    });
  });

  group('J.2 Slice 3 vertical integration (seed fixture)', () {
    late LifeJourneyComponents lifeJourney;
    late ExperienceComponents experience;
    final userId = UserId('00000000-0000-4000-8000-0000000000s3');

    setUp(() {
      final composed = _composeWithCandidates();
      lifeJourney = composed.lifeJourney;
      experience = composed.experience;
    });

    /// Case A — matching Story via catalog-aligned Discovery signal.
    test(
      'Case A: Reflection → discovery signal → seeded Story → adaptive-story',
      () async {
        final journeyId = JourneyId('j-slice3-a');
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
          reflectionId: ReflectionId('r-slice3-a'),
        );

        final result = await experience.application.getTodayExperience(
          userId: userId,
        );
        final dto = result.getOrThrow();

        expect(dto.experienceType, 'story');
        expect(dto.experienceId, 'adaptive-story-seed-story-finding-direction');
        expect(dto.title, '[Seed] Finding Direction');
        expect(dto.rationale, isNotNull);
        expect(dto.action, 'begin');
        expect(dto.journeyId, journeyId.value);
        expect(dto.target, isNotNull);
        expect(dto.target!['storyId'], 'seed-story-finding-direction');
        expect(dto.explanation.sources, isNotEmpty);
        expect(
          dto.explanation.sources.any(
            (s) => s.kind == 'narrative_theme' && s.value == 'discovery',
          ),
          isTrue,
        );
      },
    );

    /// Case B — valid signals, no matching candidate → reflection.
    test(
      'Case B: signals present but empty candidate source → default-reflection',
      () async {
        final composed = _composeWithCandidates(
          candidateSource: SeededStoryCandidateCatalog.empty(),
        );
        final lj = composed.lifeJourney;
        final exp = composed.experience;
        final journeyId = JourneyId('j-slice3-b');

        await lj.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );
        await _submitAnalyzedReflection(
          lifeJourney: lj,
          userId: userId,
          journeyId: journeyId,
          reflectionId: ReflectionId('r-slice3-b'),
        );

        final dto =
            (await exp.application.getTodayExperience(userId: userId))
                .getOrThrow();

        expect(dto.experienceType, 'reflection');
        expect(dto.experienceId, 'default-reflection');
      },
    );

    test(
      'Case B2: non-overlapping themes → fail-closed reflection',
      () async {
        final journeyId = JourneyId('j-slice3-b2');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );

        // Plant only `love` — architectural seed has no love-themed Story.
        final reflection = Reflection(
          id: ReflectionId('r-slice3-b2'),
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

        expect(dto.experienceType, 'reflection');
        expect(dto.experienceId, 'default-reflection');
      },
    );

    /// Case C — multiple matches → deterministic winner.
    test(
      'Case C: multiple overlaps select highest themeOverlapCount deterministically',
      () async {
        final journeyId = JourneyId('j-slice3-c');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );

        final reflection = Reflection(
          id: ReflectionId('r-slice3-c'),
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

        expect(first.experienceId, 'adaptive-story-seed-story-rising-again');
        expect(second.experienceId, first.experienceId);
        expect(first.title, second.title);
        expect(first.rationale, second.rationale);
      },
    );
  });

  group('J.2 Slice 3 HTTP GET /v1/experiences/today', () {
    test('Case A over HTTP returns adaptive Story DTO', () async {
      final composed = _composeWithCandidates();
      final userId = UserId('00000000-0000-4000-8000-0000000000s3');
      final principal = AuthenticatedPrincipal(
        userId: userId,
        displayName: 'Slice3',
      );
      final journeyId = JourneyId('j-http-a');

      await composed.lifeJourney.application.createJourney(
        userId: userId,
        request: CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Grow'),
        ),
      );
      await _submitAnalyzedReflection(
        lifeJourney: composed.lifeJourney,
        userId: userId,
        journeyId: journeyId,
        reflectionId: ReflectionId('r-http-a'),
      );

      final handler = _j2Handler(
        lifeJourney: composed.lifeJourney,
        experience: composed.experience,
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
      final body = response.body;
      expect(body, contains('"experienceType":"story"'));
      expect(
        body,
        contains('"experienceId":"adaptive-story-seed-story-finding-direction"'),
      );
      expect(body, contains('"kind":"narrative_theme"'));
      expect(body, contains('"value":"discovery"'));
    });
  });

  group('J.1 regression with Slice 3 wiring (Case E)', () {
    test('no Reflection themes → fail-closed reflection (not arbitrary Story)',
        () async {
      final composed = _composeWithCandidates();
      final userId = UserId('00000000-0000-4000-8000-0000000000s3');
      await composed.lifeJourney.application.createJourney(
        userId: userId,
        request: CreateJourneyRequest(
          journeyId: JourneyId('j-reg-empty'),
          vision: JourneyVision('Grow'),
        ),
      );

      final dto = (await composed.experience.application.getTodayExperience(
        userId: userId,
      ))
          .getOrThrow();

      // New journey, no reflections → empty Discovery themes → no Story.
      expect(dto.experienceId, 'default-reflection');
      expect(dto.experienceType, 'reflection');
    });

    test('omitting storyCandidatePort preserves empty fail-closed path',
        () async {
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
      // Intentionally omit storyCandidatePort (Empty default).
      final experience = ExperienceModule.compose(
        transactions: lifeJourney.transactions,
        journeyRepository: lifeJourney.journeyRepository,
        discoverySignalPort: discovery.adaptiveDiscoverySignalPort,
      );
      final userId = UserId('00000000-0000-4000-8000-0000000000s3');
      final journeyId = JourneyId('j-reg-empty-port');

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
        reflectionId: ReflectionId('r-reg-empty-port'),
      );

      final dto = (await experience.application.getTodayExperience(
        userId: userId,
      ))
          .getOrThrow();
      expect(dto.experienceId, 'default-reflection');
    });
  });
}
