import 'package:eh_platform/src/events/domain_event.dart';
import 'package:eh_platform/src/shared_kernel/strongly_typed_id.dart';

/// Convenience base for Life Journey domain events on the PF.3 event model.
abstract base class LifeJourneyEvent extends DomainEvent {
  LifeJourneyEvent({
    required String aggregateId,
    required String aggregateType,
    required String eventName,
    String? eventId,
    DateTime? occurredAt,
    String? correlationId,
    String? causationId,
    int schemaVersion = 1,
  })  : _eventName = eventName,
        super(
          eventId: eventId ?? StronglyTypedId.uuid.v4(),
          occurredAt: occurredAt ?? DateTime.now().toUtc(),
          aggregateId: aggregateId,
          aggregateType: aggregateType,
          correlationId: correlationId,
          causationId: causationId,
          schemaVersion: schemaVersion,
        );

  final String _eventName;

  @override
  String get eventName => _eventName;
}
