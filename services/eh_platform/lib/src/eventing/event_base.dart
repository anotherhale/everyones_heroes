import 'package:eh_platform/src/eventing/domain_event.dart';
import 'package:eh_platform/src/shared_kernel/ids/aggregate_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/event_id.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';

abstract base class EventBase extends DomainEvent {
  EventBase({
    required this.aggregateId,
    required this.aggregateType,
    this.correlationId,
    this.causationId,
    EventId? eventId,
    DateTime? occurredAt,
  }) : _eventId = eventId ?? EventId.generate(),
       _occurredAt = occurredAt ?? DateTime.now();

  final EventId _eventId;

  final DateTime _occurredAt;

  @override
  final AggregateId aggregateId;

  @override
  final AggregateType aggregateType;

  @override
  final String? correlationId;

  @override
  final String? causationId;

  @override
  EventId get eventId => _eventId;

  @override
  DateTime get occurredAt => _occurredAt;
}
