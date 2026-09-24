import 'package:eh_platform/eh_platform.dart';
import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/models/discoverable_story_candidate.dart';
import 'package:eh_platform/src/experience/application/models/experience_type.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/journal_response.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_reflection_repository.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeThemeAlignment (J.2 Slice 2)', () {
    test('catalog IDs pass through; unknown IDs are dropped', () {
      final aligned = NarrativeThemeAlignment.alignAll([
        NarrativeThemeReferenceIds.courage,
        const NarrativeThemeId('not-a-theme'),
        NarrativeThemeReferenceIds.purpose,
      ]);

      expect(
        aligned.map((e) => e.value).toList(),
        ['courage', 'purpose'],
      );
    });

    test('legacy self-discovery maps to catalog discovery', () {
      final aligned = NarrativeThemeAlignment.align(
        const NarrativeThemeId(NarrativeThemeAlignment.legacySelfDiscoveryValue),
      );
      expect(aligned, NarrativeThemeReferenceIds.discovery);
    });

    test('alignAll is deterministic (sorted, deduped)', () {
      final a = NarrativeThemeAlignment.alignAll([
        NarrativeThemeReferenceIds.love,
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.love,
      ]);
      final b = NarrativeThemeAlignment.alignAll([
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.love,
      ]);
      expect(a.map((e) => e.value).toList(), b.map((e) => e.value).toList());
      expect(a.map((e) => e.value).toList(), ['courage', 'love']);
    });
  });

  group('CatalogAlignedNarrativeThemeResolver', () {
    const resolver = CatalogAlignedNarrativeThemeResolver();

    test('unrecognized content falls back to catalog discovery', () async {
      final reflection = Reflection.create(
        id: ReflectionId('r1'),
        journeyId: JourneyId('j1'),
      );
      reflection.addResponse(const JournalResponse(response: 'Test'));

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, isNotEmpty);
      for (final theme in themes) {
        expect(NarrativeThemeReferenceIds.contains(theme), isTrue);
        expect(theme.value, isNot('self-discovery'));
      }
      expect(themes, [NarrativeThemeReferenceIds.discovery]);
    });

    test('matches catalog theme names from reflection content', () async {
      final reflection = Reflection.create(
        id: ReflectionId('r-content'),
        journeyId: JourneyId('j1'),
      );
      reflection.addResponse(
        const JournalResponse(
          response: 'Today I found courage when I spoke up.',
        ),
      );

      final themes = await resolver.resolveThemes(reflection);

      expect(themes, [NarrativeThemeReferenceIds.courage]);
      for (final theme in themes) {
        expect(NarrativeThemeReferenceIds.contains(theme), isTrue);
      }
    });

    test('resolution is deterministic for identical inputs', () async {
      final reflection = Reflection.create(
        id: ReflectionId('r1'),
        journeyId: JourneyId('j1'),
      );
      reflection.addResponse(
        const JournalResponse(response: 'Service and purpose matter.'),
      );

      final a = await resolver.resolveThemes(reflection);
      final b = await resolver.resolveThemes(reflection);
      expect(a.map((e) => e.value).toList(), b.map((e) => e.value).toList());
      expect(a, [
        NarrativeThemeReferenceIds.service,
        NarrativeThemeReferenceIds.purpose,
      ]);
    });
  });

  group('CatalogAlignedAdaptiveDiscoverySignalResolver', () {
    late LifeJourneyComponents lifeJourney;
    late CatalogAlignedAdaptiveDiscoverySignalResolver signalResolver;

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
      signalResolver = CatalogAlignedAdaptiveDiscoverySignalResolver(
        reflectionRepository: lifeJourney.reflectionRepository,
      );
    });

    test(
      'Reflection themes → catalog-aligned AdaptiveDiscoverySignals',
      () async {
        final userId = UserId('00000000-0000-4000-8000-0000000000j2');
        final journeyId = JourneyId('j-signal');

        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );

        final reflectionId = ReflectionId('r-signal');
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
          response: const JournalResponse(response: 'I am finding direction'),
        );
        await lifeJourney.application.submitReflection(
          userId: userId,
          request: SubmitReflectionRequest(reflectionId: reflectionId),
        );

        // AnalyzeReflection reactor adds catalog-aligned themes via
        // CatalogAlignedNarrativeThemeResolver wired in LifeJourneyModule.
        final reflection =
            await lifeJourney.reflectionRepository.findById(reflectionId);
        expect(reflection, isNotNull);
        expect(reflection!.narrativeThemes, isNotEmpty);
        for (final theme in reflection.narrativeThemes) {
          expect(NarrativeThemeReferenceIds.contains(theme), isTrue);
        }

        final journey =
            await lifeJourney.journeyRepository.findById(journeyId);
        final signals = await signalResolver.resolve(journey!);

        expect(signals.hasThemes, isTrue);
        for (final themeId in signals.narrativeThemeIds) {
          expect(NarrativeThemeReferenceIds.containsValue(themeId), isTrue);
          expect(themeId, isNot('self-discovery'));
        }
        expect(signals.narrativeThemeIds, contains('discovery'));
      },
    );

    test('legacy self-discovery stored on Reflection is aligned in signals',
        () async {
      final userId = UserId('00000000-0000-4000-8000-0000000000j3');
      final journeyId = JourneyId('j-legacy');

      await lifeJourney.application.createJourney(
        userId: userId,
        request: CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Grow'),
        ),
      );

      // Simulate pre-J.2 persisted observations (including non-catalog IDs).
      final reflection = Reflection(
        id: ReflectionId('r-legacy'),
        journeyId: journeyId,
        createdAt: DateTime.utc(2026, 1, 1),
        submittedAt: DateTime.utc(2026, 1, 2),
        narrativeThemes: const [
          NarrativeThemeId('self-discovery'),
          NarrativeThemeId('garbage-theme'),
          NarrativeThemeId('courage'),
        ],
      );
      await (lifeJourney.reflectionRepository
              as OwnedInMemoryReflectionRepository)
          .saveForUser(reflection, userId);

      final journey = await lifeJourney.journeyRepository.findById(journeyId);
      final signals = await signalResolver.resolve(journey!);

      expect(signals.narrativeThemeIds, ['courage', 'discovery']);
      expect(signals.narrativeThemeIds, isNot(contains('self-discovery')));
      expect(signals.narrativeThemeIds, isNot(contains('garbage-theme')));
    });
  });

  group('Theme overlap seam (unit; no Story persistence)', () {
    test(
      'catalog signal ID overlaps Story candidate with same canonical ID',
      () {
        const selection = DeterministicExperienceSelectionService();
        const composer = AdaptiveExperienceComposer(
          reflectionSelectionService: selection,
        );

        final journey = Journey(
          id: JourneyId('j1'),
          vision: JourneyVision('Grow'),
        );
        final signals = AdaptiveDiscoverySignals(
          narrativeThemeIds: const ['courage'],
        );
        final candidate = DiscoverableStoryCandidate(
          storyId: 'story-1',
          heroId: 'hero-1',
          title: 'Rising Again',
          matchedThemeIds: const ['courage'],
          themeOverlapCount: 1,
          patternBoost: 0.0,
          updatedAt: DateTime.utc(2026, 1, 1),
        );

        final experience = composer.compose(
          journey: journey,
          signals: signals,
          candidates: [candidate],
        );

        expect(experience.type, ExperienceType.story);
        expect(experience.id, 'adaptive-story-story-1');
        expect(
          NarrativeThemeReferenceIds.containsValue('courage'),
          isTrue,
        );
      },
    );
  });

  group('J.2 → Today integration (no Story candidates)', () {
    late LifeJourneyComponents lifeJourney;
    late ExperienceComponents experience;
    final userId = UserId('00000000-0000-4000-8000-0000000000j4');

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

    test(
      'Reflection → catalog signals → Experience Selection → default-reflection',
      () async {
        final journeyId = JourneyId('j-today');
        await lifeJourney.application.createJourney(
          userId: userId,
          request: CreateJourneyRequest(
            journeyId: journeyId,
            vision: JourneyVision('Grow'),
          ),
        );

        final reflectionId = ReflectionId('r-today');
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
          response: const JournalResponse(response: 'Finding my path'),
        );
        await lifeJourney.application.submitReflection(
          userId: userId,
          request: SubmitReflectionRequest(reflectionId: reflectionId),
        );

        final reflection =
            await lifeJourney.reflectionRepository.findById(reflectionId);
        expect(
          reflection!.narrativeThemes
              .any((t) => NarrativeThemeReferenceIds.contains(t)),
          isTrue,
        );

        final result = await experience.application.getTodayExperience(
          userId: userId,
        );
        final dto = result.getOrThrow();

        // Empty DiscoverableStoryCandidatePort → fail-closed reflection path.
        expect(dto.experienceId, 'default-reflection');
        expect(dto.experienceType, 'reflection');
      },
    );
  });
}
