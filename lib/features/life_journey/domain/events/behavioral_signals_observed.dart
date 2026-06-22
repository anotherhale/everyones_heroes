import 'package:everyonesheroes/core/eventing/event_base.dart';

import 'package:everyonesheroes/core/ids/reflection_id.dart';

import '../value_objects/behavioral_evidence.dart';

final class BehavioralEvidenceDetected extends EventBase {
  BehavioralEvidenceDetected({
    required super.aggregateId,
    required this.reflectionId,
    required this.evidence,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'Reflection');

  final ReflectionId reflectionId;

  final List<BehavioralEvidence> evidence;
}
