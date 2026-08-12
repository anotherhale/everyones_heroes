import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_quest_request.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';

import 'package:everyonesheroes/features/life_journey/domain/repositories/journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/quest_repository.dart';

final class CreateQuestUseCase implements UseCase<CreateQuestRequest, Quest> {
  const CreateQuestUseCase({
    required this._journeyRepository,
    required this._questRepository,
    required this._eventBus,
  });

  final JourneyRepository _journeyRepository;

  final QuestRepository _questRepository;

  final EventBus _eventBus;

  @override
  Future<Result<Quest>> execute(CreateQuestRequest request) async {
    try {
      final Journey? journey = await _journeyRepository.findById(
        request.journeyId,
      );

      if (journey == null) {
        return Failure(
          'Journey not found: '
          '${request.journeyId.value}',
        );
      }

      final quest = Quest.create(
        id: request.questId,
        journeyId: request.journeyId,
        title: request.title,
      );

      journey.attachQuest(quest.id);

      await _questRepository.save(quest);

      await _journeyRepository.save(journey);

      final events = [
        ...quest.pullDomainEvents(),
        ...journey.pullDomainEvents(),
      ];

      for (final event in events) {
        await _eventBus.publish(event);
      }

      return Success(quest);
    } catch (e) {
      return Failure('Failed to create quest: $e');
    }
  }
}
