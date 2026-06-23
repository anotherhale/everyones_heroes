import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/mission_title.dart';

final class CreateMissionRequest {
  const CreateMissionRequest({
    required this.questId,
    required this.missionId,
    required this.title,
  });

  final QuestId questId;

  final MissionId missionId;

  final MissionTitle title;
}
