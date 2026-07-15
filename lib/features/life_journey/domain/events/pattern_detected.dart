import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/behavior_pattern.dart';

final class PatternDetected extends EventBase {
  PatternDetected({
    required super.aggregateId,
    required this.patterns,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'Journey');

  final List<BehaviorPattern> patterns;
}
