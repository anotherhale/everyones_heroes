import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';

final class MissionCreated extends EventBase {
  MissionCreated({
    required super.aggregateId,
    required this.missionId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: AggregateType.quest);

  final MissionId missionId;
}
