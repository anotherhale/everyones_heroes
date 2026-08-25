import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/eventing/aggregate_type.dart';

final class JourneyCreated extends EventBase {
  JourneyCreated({
    required super.aggregateId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.journey);
}
