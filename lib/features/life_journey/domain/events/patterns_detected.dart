import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/features/life_journey/domain/domain.dart';

final class PatternsDetected extends EventBase {
  PatternsDetected({
    required super.aggregateId,
    required this.patterns,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'BehavioralEvidence');

  final List<BehaviorPattern> patterns;
}
