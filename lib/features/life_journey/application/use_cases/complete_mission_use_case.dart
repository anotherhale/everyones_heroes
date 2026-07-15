import 'package:everyonesheroes/features/life_journey/application/dto/requests/complete_mission_request.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/quest_repository.dart';

final class CompleteMissionUseCase {
  const CompleteMissionUseCase({
    required this._questRepository,
    required this._eventBus,
  });

  final QuestRepository _questRepository;

  final EventBus _eventBus;

  Future<Result<Quest>> execute(CompleteMissionRequest request) async {
    try {
      final quest = await _questRepository.findById(request.questId);

      if (quest == null) {
        return Failure('Quest not found: ${request.questId.value}');
      }

      quest.completeMission(request.missionId);

      await _questRepository.save(quest);

      final events = quest.pullDomainEvents();

      for (final event in events) {
        await _eventBus.publish(event);
      }

      return Success(quest);
    } catch (e) {
      return Failure('Failed to complete mission: $e');
    }
  }
}
