import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/detect_pattern_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:flutter_test/flutter_test.dart';

late InMemoryJourneyRepository journeyRepository;
late InMemoryReflectionRepository reflectionRepository;
late PatternDetector detector;
late EventBus eventBus;
late DefaultDetectPatternUseCase useCase;

Journey createJourney({JourneyId? id, String vision = 'Become healthier'}) {
  return Journey.create(
    id: id ?? JourneyId.generate(),
    vision: JourneyVision(vision),
  );
}

Journey createUpdatedJourney(JourneyId id) {
  return Journey(
    id: id,
    vision: JourneyVision('Updated'),
    currentChapter: JourneyChapter.commitment,
  );
}

final class TestEventBus implements EventBus {
  final List<DomainEvent> publishedEvents = [];

  @override
  Future<void> publish(DomainEvent event) async {
    publishedEvents.add(event);
  }
}

final class TestPatternDetector implements PatternDetector {
  List<BehavioralEvidence> receivedEvidence = [];
  List<BehaviorPattern> patternsToReturn = [];

  @override
  List<BehaviorPattern> detect({required List<BehavioralEvidence> evidence}) {
    receivedEvidence = evidence;
    return patternsToReturn;
  }
}

BehavioralEvidence createEvidence({
  required BehavioralEvidenceType type,
  required ReflectionId reflectionId,
  required DateTime observedAt,
  double strength = 0.8,
}) {
  return BehavioralEvidence(
    type: type,
    source: ReflectionEvidenceSource(reflectionId: reflectionId),
    strength: Strength(strength),
    observedAt: observedAt,
  );
}

void main() {
  setUp(() {
    journeyRepository = InMemoryJourneyRepository();
    reflectionRepository = InMemoryReflectionRepository();

    detector = TestPatternDetector(); //RuleBasedPatternDetector(rules: [ConsistencyPatternRule()]);
    eventBus = TestEventBus();

    useCase = DefaultDetectPatternUseCase(
      journeyRepository: journeyRepository,
      reflectionRepository: reflectionRepository,
      detector: detector,
      eventBus: eventBus,
    );
  });
  group('DetectPatternsUseCase', () {
    test('detects patterns from journey reflections', () async {
      final journey = createJourney();

      await journeyRepository.save(journey);

      final reflection1 = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: journey.id,
      );
      reflection1.addResponse(const JournalResponse(response: 'Test'));
      reflection1.submit();

      final evidence1 = createEvidence(
        type: BehavioralEvidenceType.consistency,
        reflectionId: reflection1.id,
        observedAt: DateTime(2026, 8, 1),
      );

      reflection1.addBehavioralEvidence([evidence1]);

      final reflection2 = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: journey.id,
      );
      reflection2.addResponse(const JournalResponse(response: 'Test'));
      reflection2.submit();

      reflection2.addBehavioralEvidence([
        createEvidence(
          type: BehavioralEvidenceType.consistency,
          reflectionId: reflection2.id,
          observedAt: DateTime(2026, 8, 5),
        ),
      ]);

      final reflection3 = Reflection.create(
        id: ReflectionId.generate(),
        journeyId: journey.id,
      );
      reflection3.addResponse(const JournalResponse(response: 'Test'));
      reflection3.submit();

      reflection3.addBehavioralEvidence([
        createEvidence(
          type: BehavioralEvidenceType.consistency,
          reflectionId: reflection3.id,
          observedAt: DateTime(2026, 8, 10),
        ),
      ]);

      await reflectionRepository.save(reflection1);
      await reflectionRepository.save(reflection2);
      await reflectionRepository.save(reflection3);

      final result = await useCase.execute(journey.id);

      expect(result, isA<Success<List<BehaviorPattern>>>());
    });
  });
}
