import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';

final class BehavioralEvidenceDetected extends EventBase {
  BehavioralEvidenceDetected({
    required ReflectionId reflectionId,
    required this.journeyId,
    required this.evidence,
    super.correlationId,
    super.causationId,
  }) : super(
         aggregateId: reflectionId,
         aggregateType: AggregateType.reflection,
       );

  final JourneyId journeyId;

  final List<BehavioralEvidence> evidence;
}
