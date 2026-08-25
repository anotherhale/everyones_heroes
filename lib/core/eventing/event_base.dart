import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/event_id.dart';
import 'package:everyonesheroes/core/eventing/aggregate_type.dart';

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
