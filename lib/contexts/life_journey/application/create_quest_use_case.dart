import 'package:everyonesheroes/contexts/life_journey/application/create_quest_request.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';

import 'package:everyonesheroes/features/life_journey/domain/repositories/journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/quest_repository.dart';

final class CreateQuestUseCase {
  const CreateQuestUseCase({
    required JourneyRepository journeyRepository,
    required QuestRepository questRepository,
    required EventBus eventBus,
  }) : _journeyRepository = journeyRepository,
       _questRepository = questRepository,
       _eventBus = eventBus;

  final JourneyRepository _journeyRepository;

  final QuestRepository _questRepository;

  final EventBus _eventBus;

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

      final events = [...quest.domainEvents, ...journey.domainEvents];

      for (final event in events) {
        await _eventBus.publish(event);
      }

      quest.clearDomainEvents();
      journey.clearDomainEvents();

      return Success(quest);
    } catch (e) {
      return Failure('Failed to create quest: $e');
    }
  }
}
