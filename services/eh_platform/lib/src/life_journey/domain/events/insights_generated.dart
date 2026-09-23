import 'package:eh_platform/src/eventing/event_base.dart';

import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';

import '../value_objects/insight.dart';

final class InsightsGenerated extends EventBase {
  InsightsGenerated({
    required super.aggregateId,
    required this.reflectionId,
    required this.insights,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.reflection);

  final ReflectionId reflectionId;

  final List<Insight> insights;
}
