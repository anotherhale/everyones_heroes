import 'package:everyonesheroes/core/ids/event_id.dart';

abstract base class DomainEvent {
  EventId get eventId;

  DateTime get occurredAt;

  String get aggregateId;

  String get aggregateType;

  String? get correlationId;

  String? get causationId;
}
