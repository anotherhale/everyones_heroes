import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';

final class CreateReflectionRequest {
  const CreateReflectionRequest({
    required this.reflectionId,
    required this.journeyId,
    this.questId,
    this.missionId,
  });

  final ReflectionId reflectionId;

  final JourneyId journeyId;

  final QuestId? questId;

  final MissionId? missionId;
}