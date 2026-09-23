import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/mission_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/quest_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';

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
