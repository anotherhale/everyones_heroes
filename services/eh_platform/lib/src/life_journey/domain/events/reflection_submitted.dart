import 'package:eh_platform/src/life_journey/domain/events/life_journey_event.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/mission_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/quest_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';

final class ReflectionSubmitted extends LifeJourneyEvent {
  ReflectionSubmitted({
    required this.reflectionId,
    required this.journeyId,
    this.questId,
    this.missionId,
    super.eventId,
    super.occurredAt,
    super.correlationId,
    super.causationId,
  }) : super(
          aggregateId: reflectionId.value,
          aggregateType: 'reflection',
          eventName: 'ReflectionSubmitted',
        );

  final ReflectionId reflectionId;
  final JourneyId journeyId;
  final QuestId? questId;
  final MissionId? missionId;
}
