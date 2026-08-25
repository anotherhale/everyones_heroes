import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/event_id.dart';
import 'package:everyonesheroes/core/eventing/aggregate_type.dart';

abstract base class DomainEvent {
  EventId get eventId;

  DateTime get occurredAt;

  AggregateId get aggregateId;

  AggregateType get aggregateType;

  String? get correlationId;

  String? get causationId;
}
