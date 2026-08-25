import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';
import 'package:everyonesheroes/core/eventing/aggregate_type.dart';

final class PatternsDetected extends EventBase {
  PatternsDetected({
    required super.aggregateId,
    required this.patterns,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.behavioralEvidence);

  final List<BehaviorPattern> patterns;
}
