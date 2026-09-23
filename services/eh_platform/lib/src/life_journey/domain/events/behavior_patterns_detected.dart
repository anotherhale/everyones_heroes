import 'package:eh_platform/src/life_journey/domain/events/life_journey_event.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';

final class BehaviorPatternsDetected extends LifeJourneyEvent {
  BehaviorPatternsDetected({
    required JourneyId aggregateId,
    required List<BehaviorPattern> patterns,
    super.eventId,
    super.occurredAt,
    super.correlationId,
    super.causationId,
  })  : patterns = List.unmodifiable(patterns),
        super(
          aggregateId: aggregateId.value,
          aggregateType: 'journey',
          eventName: 'BehaviorPatternsDetected',
        );

  final List<BehaviorPattern> patterns;
}
