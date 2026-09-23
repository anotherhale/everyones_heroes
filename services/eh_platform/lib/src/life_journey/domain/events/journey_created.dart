import 'package:eh_platform/src/eventing/event_base.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';

final class JourneyCreated extends EventBase {
  JourneyCreated({
    required super.aggregateId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.journey);
}
