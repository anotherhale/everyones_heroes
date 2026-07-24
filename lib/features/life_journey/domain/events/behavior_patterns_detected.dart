import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';
import 'package:everyonesheroes/features/life_journey/domain/patterns/behavior_pattern.dart';

final class BehaviorPatternsDetected extends EventBase {
  BehaviorPatternsDetected({
    required super.aggregateId,
    required this.patterns,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.journey);

  final List<BehaviorPattern> patterns;
}
