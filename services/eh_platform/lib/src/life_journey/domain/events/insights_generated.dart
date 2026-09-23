import 'package:eh_platform/src/life_journey/domain/events/life_journey_event.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/insight.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';

final class InsightsGenerated extends LifeJourneyEvent {
  InsightsGenerated({
    required this.reflectionId,
    required List<Insight> insights,
    super.eventId,
    super.occurredAt,
    super.correlationId,
    super.causationId,
  })  : insights = List.unmodifiable(insights),
        super(
          aggregateId: reflectionId.value,
          aggregateType: 'reflection',
          eventName: 'InsightsGenerated',
        );

  final ReflectionId reflectionId;
  final List<Insight> insights;
}
