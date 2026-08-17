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

import '../../../../helpers/event_assertions.dart';

void main() {
  group('BehavioralEvidenceDetectedReactor', () {
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

    test(
      'detects patterns when behavioral evidence detected event is published',
      () async {
        final journey = Journey.create(
          id: JourneyId.generate(),
          vision: JourneyVision('Become healthier'),
        );

        await journeyRepository.save(journey);

        final reflection1 = Reflection.create(
          id: ReflectionId.generate(),
          journeyId: journey.id,
        );
        reflection1.addResponse(const JournalResponse(response: 'Test'));
        reflection1.submit();

        final reflection2 = Reflection.create(
          id: ReflectionId.generate(),
          journeyId: journey.id,
        );
        reflection2.addResponse(const JournalResponse(response: 'Test'));
        reflection2.submit();

        final reflection3 = Reflection.create(
          id: ReflectionId.generate(),
          journeyId: journey.id,
        );
        reflection3.addResponse(const JournalResponse(response: 'Test'));
        reflection3.submit();

        final evidence1 = BehavioralEvidence(
          type: BehavioralEvidenceType.discipline,
          source: ReflectionEvidenceSource(reflectionId: reflection1.id),
          strength: Strength(0.8),
          observedAt: DateTime(2026, 8, 1),
        );

        final evidence2 = BehavioralEvidence(
          type: BehavioralEvidenceType.discipline,
          source: ReflectionEvidenceSource(reflectionId: reflection2.id),
          strength: Strength(0.8),
          observedAt: DateTime(2026, 8, 5),
        );

        final evidence3 = BehavioralEvidence(
          type: BehavioralEvidenceType.discipline,
          source: ReflectionEvidenceSource(reflectionId: reflection3.id),
          strength: Strength(0.8),
          observedAt: DateTime(2026, 8, 10),
        );

        reflection1.addBehavioralEvidence([evidence1]);
        reflection2.addBehavioralEvidence([evidence2]);
        reflection3.addBehavioralEvidence([evidence3]);

        await reflectionRepository.save(reflection1);
        await reflectionRepository.save(reflection2);
        await reflectionRepository.save(reflection3);

        await eventBus.publish(
          BehavioralEvidenceDetected(
            reflectionId: reflection1.id,
            journeyId: journey.id,
            evidence: [evidence1],
          ),
        );

        final envelopes = await eventStore.allEvents();
        final events = envelopes
            .map((envelope) => envelope.event)
            .toList(growable: false);

        expectEventRaised<BehavioralEvidenceDetected>(events);
        expectEventRaised<BehaviorPatternsDetected>(events);

        final patternsEvent = expectSingleEvent<BehaviorPatternsDetected>(
          events,
        );

        expect(patternsEvent.aggregateId, journey.id);
        expect(patternsEvent.patterns, hasLength(1));
        expect(
          patternsEvent.patterns.single.type,
          BehaviorPatternType.consistency,
        );

        final updatedJourney = await journeyRepository.findById(journey.id);

        expect(updatedJourney, isNotNull);
        expect(updatedJourney!.behaviorPatterns, hasLength(1));
        expect(
          updatedJourney.behaviorPatterns.single.type,
          BehaviorPatternType.consistency,
        );
      },
    );
  });
}
