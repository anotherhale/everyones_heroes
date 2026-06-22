import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

final class CompleteMissionRequest {
  const CompleteMissionRequest({
    required this.questId,
    required this.missionId,
  });

  final QuestId questId;

  final MissionId missionId;
}
