import 'package:eh_platform/src/shared_kernel/ids/aggregate_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/event_id.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';

abstract base class DomainEvent {
  EventId get eventId;

  DateTime get occurredAt;

  AggregateId get aggregateId;

  AggregateType get aggregateType;

  String? get correlationId;

  String? get causationId;
}
