import 'package:eh_platform/src/eventing/event_base.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/life_journey/domain/domain.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';

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
