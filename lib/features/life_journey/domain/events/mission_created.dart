import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';

final class MissionCreated extends EventBase {
  MissionCreated({
    required super.aggregateId,
    required this.missionId,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'Quest');

  final MissionId missionId;
}
