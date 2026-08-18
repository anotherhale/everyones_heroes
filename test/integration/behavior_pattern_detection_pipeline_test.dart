import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/application/reactors/behavioral_evidence_detected_reactor.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/detect_pattern_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/services/rule_based/rule_based_pattern_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Behavior Pattern Detection Pipeline', () {
    late InMemoryJourneyRepository journeyRepository;
    late InMemoryReflectionRepository reflectionRepository;
    late InMemoryEventStore eventStore;
    late InMemoryEventDispatcher dispatcher;
    late EventBus eventBus;

    setUp(() {
      journeyRepository = InMemoryJourneyRepository();
      reflectionRepository = InMemoryReflectionRepository();
      eventStore = InMemoryEventStore();
      dispatcher = InMemoryEventDispatcher();

      eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );

      final detector = const RuleBasedPatternDetector(
        rules: [
          ConsistencyPatternRule(),
          CouragePatternRule(),
          LeadershipPatternRule(),
          RecoveryPatternRule(),
          ResponsibilityPatternRule(),
          ServicePatternRule(),
        ],
      );

      final detectPatternUseCase = DefaultDetectPatternUseCase(
        journeyRepository: journeyRepository,
        reflectionRepository: reflectionRepository,
        detector: detector,
        eventBus: eventBus,
      );

      dispatcher.register<BehavioralEvidenceDetected>(
        BehavioralEvidenceDetectedReactor(detectPattern: detectPatternUseCase),
      );
    });

    Future<List<Reflection>> createDisciplineReflections({
      required Journey journey,
      required int count,
    }) async {
      final reflections = <Reflection>[];

      for (var i = 0; i < count; i++) {
        final reflection = Reflection.create(
          id: ReflectionId.generate(),
          journeyId: journey.id,
        );

        reflection.addResponse(
          const JournalResponse(response: 'I followed through.'),
        );

        reflection.submit();

        reflection.addBehavioralEvidence([
          BehavioralEvidence(
            type: BehavioralEvidenceType.discipline,
            source: ReflectionEvidenceSource(reflectionId: reflection.id),
            strength: const Strength(0.8),
            observedAt: DateTime(2026, 8, 1 + (i * 5)),
          ),
        ]);

        await reflectionRepository.save(reflection);
        reflections.add(reflection);
      }

      return reflections;
    }

    test('single reflection flows through the pipeline without '
        'creating an insufficiently supported pattern', () async {
      final journey = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become healthier'),
      );

      await journeyRepository.save(journey);

      final reflections = await createDisciplineReflections(
        journey: journey,
        count: 1,
      );

      final evidence = reflections.first.behavioralEvidence.single;

      await eventBus.publish(
        BehavioralEvidenceDetected(
          reflectionId: reflections.first.id,
          journeyId: journey.id,
          evidence: [evidence],
        ),
      );

      final updatedJourney = await journeyRepository.findById(journey.id);

      expect(updatedJourney, isNotNull);
      expect(updatedJourney!.behaviorPatterns, isEmpty);
    });

    test(
      'multiple reflections produce a pattern from accumulated evidence',
      () async {
        final journey = Journey.create(
          id: JourneyId.generate(),
          vision: JourneyVision('Become healthier'),
        );

        await journeyRepository.save(journey);

        final reflections = await createDisciplineReflections(
          journey: journey,
          count: 3,
        );

        final firstEvidence = reflections.first.behavioralEvidence.single;

        await eventBus.publish(
          BehavioralEvidenceDetected(
            reflectionId: reflections.first.id,
            journeyId: journey.id,
            evidence: [firstEvidence],
          ),
        );

        final updatedJourney = await journeyRepository.findById(journey.id);

        expect(updatedJourney, isNotNull);
        expect(updatedJourney!.behaviorPatterns, hasLength(1));

        final pattern = updatedJourney.behaviorPatterns.single;

        expect(pattern.type, BehaviorPatternType.consistency);
        expect(pattern.supportingEvidence, hasLength(3));
      },
    );

    test('repeated evidence does not create duplicate patterns', () async {
      final journey = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become healthier'),
      );

      await journeyRepository.save(journey);

      final reflections = await createDisciplineReflections(
        journey: journey,
        count: 3,
      );

      final event = BehavioralEvidenceDetected(
        reflectionId: reflections.first.id,
        journeyId: journey.id,
        evidence: [reflections.first.behavioralEvidence.single],
      );

      await eventBus.publish(event);
      await eventBus.publish(event);

      final updatedJourney = await journeyRepository.findById(journey.id);

      expect(updatedJourney, isNotNull);
      expect(updatedJourney!.behaviorPatterns, hasLength(1));
      expect(
        updatedJourney.behaviorPatterns.single.supportingEvidence,
        hasLength(3),
      );
    });

    test(
      'no changes does not publish another BehaviorPatternsDetected event',
      () async {
        final journey = Journey.create(
          id: JourneyId.generate(),
          vision: JourneyVision('Become healthier'),
        );

        await journeyRepository.save(journey);

        final reflections = await createDisciplineReflections(
          journey: journey,
          count: 3,
        );

        final event = BehavioralEvidenceDetected(
          reflectionId: reflections.first.id,
          journeyId: journey.id,
          evidence: [reflections.first.behavioralEvidence.single],
        );

        await eventBus.publish(event);

        final firstEvents = await eventStore.allEvents();

        final firstPatternEvents = firstEvents
            .map((envelope) => envelope.event)
            .whereType<BehaviorPatternsDetected>()
            .length;

        expect(firstPatternEvents, 1);

        await eventBus.publish(event);

        final secondEvents = await eventStore.allEvents();

        final secondPatternEvents = secondEvents
            .map((envelope) => envelope.event)
            .whereType<BehaviorPatternsDetected>()
            .length;

        expect(secondPatternEvents, 1);
      },
    );

    test('additional evidence strengthens the existing pattern', () async {
      final journey = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become healthier'),
      );

      await journeyRepository.save(journey);

      final initialReflections = await createDisciplineReflections(
        journey: journey,
        count: 3,
      );

      await eventBus.publish(
        BehavioralEvidenceDetected(
          reflectionId: initialReflections.first.id,
          journeyId: journey.id,
          evidence: [initialReflections.first.behavioralEvidence.single],
        ),
      );

      final firstJourney = await journeyRepository.findById(journey.id);

      expect(firstJourney, isNotNull);
      expect(firstJourney!.behaviorPatterns, hasLength(1));

      final firstPattern = firstJourney.behaviorPatterns.single;

      final additionalReflections = await createDisciplineReflections(
        journey: journey,
        count: 1,
      );

      await eventBus.publish(
        BehavioralEvidenceDetected(
          reflectionId: additionalReflections.first.id,
          journeyId: journey.id,
          evidence: [additionalReflections.first.behavioralEvidence.single],
        ),
      );

      final secondJourney = await journeyRepository.findById(journey.id);

      expect(secondJourney, isNotNull);
      expect(secondJourney!.behaviorPatterns, hasLength(1));

      final secondPattern = secondJourney.behaviorPatterns.single;

      expect(secondPattern.type, BehaviorPatternType.consistency);
      expect(
        secondPattern.supportingEvidence.length,
        greaterThan(firstPattern.supportingEvidence.length),
      );
    });
  });
}
