import 'package:eh_platform/src/life_journey/domain/events/life_journey_event.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';

final class JourneyCreated extends LifeJourneyEvent {
  JourneyCreated({
    required JourneyId aggregateId,
    super.eventId,
    super.occurredAt,
    super.correlationId,
    super.causationId,
  }) : super(
          aggregateId: aggregateId.value,
          aggregateType: 'journey',
          eventName: 'JourneyCreated',
        );
}
