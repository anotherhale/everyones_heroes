import 'package:eh_platform/src/eventing/event_base.dart';

import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/mission_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/quest_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/eventing/aggregate_type.dart';

final class ReflectionSubmitted extends EventBase {
  ReflectionSubmitted({
    required super.aggregateId,
    required this.reflectionId,
    required this.journeyId,
    this.questId,
    this.missionId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.reflection);

  final ReflectionId reflectionId;

  final JourneyId journeyId;

  final QuestId? questId;

  final MissionId? missionId;
}
