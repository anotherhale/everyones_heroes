import 'package:eh_platform/src/life_journey/domain/events/life_journey_event.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/behavioral_evidence.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';

final class BehavioralEvidenceDetected extends LifeJourneyEvent {
  BehavioralEvidenceDetected({
    required this.reflectionId,
    required this.journeyId,
    required List<BehavioralEvidence> evidence,
    super.eventId,
    super.occurredAt,
    super.correlationId,
    super.causationId,
  })  : evidence = List.unmodifiable(evidence),
        super(
          aggregateId: reflectionId.value,
          aggregateType: 'reflection',
          eventName: 'BehavioralEvidenceDetected',
        );

  final ReflectionId reflectionId;
  final JourneyId journeyId;
  final List<BehavioralEvidence> evidence;
}
