import 'dart:convert';

import 'package:eh_platform/eh_platform.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/journal_response.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

/// J.2 Slice 5 — HTTP ingest → projection → Today adaptive-story-*.
void main() {
  group('J.2 Slice 5 productization vertical', () {
    late InMemoryDiscoverableStoryCandidateProjection projection;
    late LifeJourneyComponents lifeJourney;
    late ExperienceComponents experience;
    late HeroStoryComponents heroStory;
    late AuthenticatedPrincipal principal;
    late UserId userId;

    setUp(() {
      projection = InMemoryDiscoverableStoryCandidateProjection();
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
      heroStory = HeroStoryModule.compose(
        candidateSource: projection,
        projection: projection,
      );
      experience = ExperienceModule.compose(
        transactions: lifeJourney.transactions,
        journeyRepository: lifeJourney.journeyRepository,
        discoverySignalPort: discovery.adaptiveDiscoverySignalPort,
        storyCandidatePort: heroStory.storyCandidatePort,
      );
      userId = UserId('user-s5');
      principal = AuthenticatedPrincipal(
        userId: userId,
        displayName: 'Slice5',
      );
    });

    Handler authedHandler() {
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
          .addHandler(
            Cascade()
                .add(lifeJourney.handler)
                .add(experience.handler)
                .add(heroStory.handler!)
                .handler,
          );
    }

    Future<void> submitFindingDirectionReflection(
      JourneyId journeyId,
      ReflectionId reflectionId,
    ) async {
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

    Map<String, Object?> facts({
      required String storyId,
      String lifecycle = 'published',
      List<String> themes = const ['discovery', 'purpose'],
    }) {
      return {
        'storyId': storyId,
        'heroId': 'hero-s5',
        'title': 'Finding Direction',
        'themeIds': themes,
        'updatedAt': '2026-06-01T00:00:00.000Z',
        'lifecycleStatus': lifecycle,
        'storyVisibility': 'public',
        'hasProvisionalNarrative': false,
        'hasAuthoritativeRepresentation': true,
        'heroStatus': 'active',
        'heroVisibility': 'public',
      };
    }

    test(
      'HTTP ingest of eligible facts → Today adaptive-story-*',
      () async {
        final journeyId = JourneyId('j-s5-a');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );
        await submitFindingDirectionReflection(
          journeyId,
          ReflectionId('r-s5-a'),
        );

        final server = await shelf_io.serve(
          authedHandler(),
          '127.0.0.1',
          0,
        );
        addTearDown(() => server.close(force: true));
        final base = 'http://127.0.0.1:${server.port}';

        final ingest = await http.put(
          Uri.parse('$base/v1/hero-story/candidates/story-s5-live'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(facts(storyId: 'story-s5-live')),
        );
        expect(ingest.statusCode, 200);
        expect(jsonDecode(ingest.body)['wasUpserted'], isTrue);

        final relevant = await heroStory.storyCandidatePort.findRelevant(
          AdaptiveDiscoverySignals(narrativeThemeIds: const ['discovery']),
        );
        expect(relevant, isNotEmpty);
        expect(relevant.first.storyId, 'story-s5-live');

        final today = await http.get(Uri.parse('$base/v1/experiences/today'));
        expect(today.statusCode, 200);
        expect(today.body, contains('"experienceType":"story"'));
        expect(
          today.body,
          contains('"experienceId":"adaptive-story-story-s5-live"'),
        );
      },
    );

    test(
      'HTTP ingest of archived facts → Today falls back to reflection',
      () async {
        final journeyId = JourneyId('j-s5-b');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );
        await submitFindingDirectionReflection(
          journeyId,
          ReflectionId('r-s5-b'),
        );

        await heroStory.projectCandidate!.execute(
          StoryCandidateEligibilityFacts.fromJson(
            facts(storyId: 'story-s5-archive'),
          ),
        );

        final server = await shelf_io.serve(
          authedHandler(),
          '127.0.0.1',
          0,
        );
        addTearDown(() => server.close(force: true));
        final base = 'http://127.0.0.1:${server.port}';

        final before = await http.get(Uri.parse('$base/v1/experiences/today'));
        expect(before.body, contains('adaptive-story-story-s5-archive'));

        final archive = await http.put(
          Uri.parse('$base/v1/hero-story/candidates/story-s5-archive'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(
            facts(storyId: 'story-s5-archive', lifecycle: 'archived'),
          ),
        );
        expect(archive.statusCode, 200);
        expect(jsonDecode(archive.body)['wasUpserted'], isFalse);
        expect(await projection.exists('story-s5-archive'), isFalse);

        final after = await http.get(Uri.parse('$base/v1/experiences/today'));
        expect(after.statusCode, 200);
        expect(after.body, isNot(contains('adaptive-story-story-s5-archive')));
        expect(after.body, contains('"experienceType":"reflection"'));
      },
    );
  });
}
