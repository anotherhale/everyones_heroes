import 'package:eh_platform/src/eventing/event_base.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';
import 'package:eh_platform/src/life_journey/domain/patterns/behavior_pattern.dart';

final class BehaviorPatternsDetected extends EventBase {
  BehaviorPatternsDetected({
    required super.aggregateId,
    required this.patterns,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.journey);

  final List<BehaviorPattern> patterns;
}
