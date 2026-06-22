import 'package:everyonesheroes/core/eventing/event_base.dart';

final class JourneyCreated extends EventBase {
  JourneyCreated({
    required super.aggregateId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'Journey');
}
