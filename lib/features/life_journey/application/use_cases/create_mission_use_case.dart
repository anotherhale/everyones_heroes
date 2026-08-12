import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_mission_request.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';

import 'package:everyonesheroes/features/life_journey/domain/repositories/quest_repository.dart';

final class CreateMissionUseCase
    implements UseCase<CreateMissionRequest, Quest> {
  const CreateMissionUseCase({
    required this._questRepository,
    required this._eventBus,
  });

  final QuestRepository _questRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Quest>> execute(CreateMissionRequest request) async {
    try {
      final quest = await _questRepository.findById(request.questId);

      if (quest == null) {
        return Failure('Quest not found: ${request.questId.value}');
      }

      quest.addMission(missionId: request.missionId, title: request.title);

      await _questRepository.save(quest);

      final events = quest.pullDomainEvents();

      for (final event in events) {
        await _eventBus.publish(event);
      }

      return Success(quest);
    } catch (e) {
      return Failure('Failed to create mission: $e');
    }
  }
}
