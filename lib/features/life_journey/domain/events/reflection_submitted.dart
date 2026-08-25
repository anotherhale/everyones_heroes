import 'package:everyonesheroes/core/eventing/event_base.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/eventing/aggregate_type.dart';

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
