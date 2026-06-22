import 'package:everyonesheroes/core/eventing/event_base.dart';

import 'package:everyonesheroes/core/ids/reflection_id.dart';

import '../value_objects/insight.dart';

final class InsightsGenerated extends EventBase {
  InsightsGenerated({
    required super.aggregateId,
    required this.reflectionId,
    required this.insights,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'Reflection');

  final ReflectionId reflectionId;

  final List<Insight> insights;
}
