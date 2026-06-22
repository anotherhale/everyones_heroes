import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_quest_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/contexts/life_journey/application/create_quest_request.dart';
import 'package:everyonesheroes/contexts/life_journey/application/create_quest_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/quest_created.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';

void main() {
  group('CreateQuestUseCase', () {
    late InMemoryJourneyRepository journeyRepository;
    late InMemoryQuestRepository questRepository;

    late InMemoryEventStore eventStore;
    late InMemoryEventDispatcher dispatcher;
    late InMemoryEventBus eventBus;

    late CreateQuestUseCase useCase;

    late Journey existingJourney;

    setUp(() async {
      journeyRepository = InMemoryJourneyRepository();
      questRepository = InMemoryQuestRepository();

      eventStore = InMemoryEventStore();
      dispatcher = InMemoryEventDispatcher();

      eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );

      useCase = CreateQuestUseCase(
        journeyRepository: journeyRepository,
        questRepository: questRepository,
        eventBus: eventBus,
      );

      existingJourney = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become healthier'),
      );

      existingJourney.clearDomainEvents();
      await journeyRepository.save(existingJourney);
    });

    test('creates quest', () async {
      final result = await useCase.execute(
        CreateQuestRequest(
          questId: QuestId.generate(),
          journeyId: existingJourney.id,
          title: QuestTitle('Lose 20 Pounds'),
        ),
      );

      expect(result, isA<Success<Quest>>());
    });

    test('saves quest', () async {
      final questId = QuestId.generate();

      await useCase.execute(
        CreateQuestRequest(
          questId: questId,
          journeyId: existingJourney.id,
          title: QuestTitle('Lose 20 Pounds'),
        ),
      );

      final quest = await questRepository.findById(questId);

      expect(quest, isNotNull);
    });

    test('attaches quest to journey', () async {
      final questId = QuestId.generate();

      await useCase.execute(
        CreateQuestRequest(
          questId: questId,
          journeyId: existingJourney.id,
          title: QuestTitle('Lose 20 Pounds'),
        ),
      );

      final updatedJourney = await journeyRepository.findById(
        existingJourney.id,
      );

      expect(updatedJourney!.hasQuest(questId), isTrue);
    });

    test('persists updated journey', () async {
      final questId = QuestId.generate();

      await useCase.execute(
        CreateQuestRequest(
          questId: questId,
          journeyId: existingJourney.id,
          title: QuestTitle('Lose 20 Pounds'),
        ),
      );

      final updatedJourney = await journeyRepository.findById(
        existingJourney.id,
      );

      expect(updatedJourney!.activeQuestIds, contains(questId));
    });

    test('returns created quest', () async {
      final questId = QuestId.generate();

      final result = await useCase.execute(
        CreateQuestRequest(
          questId: questId,
          journeyId: existingJourney.id,
          title: QuestTitle('Lose 20 Pounds'),
        ),
      );

      result.fold(
        onSuccess: (quest) {
          expect(quest.id, questId);
        },
        onFailure: fail,
      );
    });

    test('publishes QuestCreated event', () async {
      final questId = QuestId.generate();

      await useCase.execute(
        CreateQuestRequest(
          questId: questId,
          journeyId: existingJourney.id,
          title: QuestTitle('Lose 20 Pounds'),
        ),
      );

      final envelopes = await eventStore.allEvents();

      expect(envelopes.length, 1);

      expect(envelopes.single.event, isA<QuestCreated>());
    });

    test('fails when journey does not exist', () async {
      final result = await useCase.execute(
        CreateQuestRequest(
          questId: QuestId.generate(),
          journeyId: JourneyId.generate(),
          title: QuestTitle('Lose 20 Pounds'),
        ),
      );

      expect(result, isA<Failure<Quest>>());
    });
  });
}
