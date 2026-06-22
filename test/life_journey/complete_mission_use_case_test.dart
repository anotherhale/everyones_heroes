import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_quest_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';

import 'package:everyonesheroes/contexts/life_journey/application/complete_mission_request.dart';
import 'package:everyonesheroes/contexts/life_journey/application/complete_mission_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/mission_completed.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/quest_completed.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/mission_title.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';

void main() {
  group('CompleteMissionUseCase', () {
    late InMemoryQuestRepository repository;

    late InMemoryEventStore eventStore;
    late InMemoryEventDispatcher dispatcher;
    late InMemoryEventBus eventBus;

    late CompleteMissionUseCase useCase;

    late Quest existingQuest;

    late MissionId missionId;

    setUp(() async {
      repository = InMemoryQuestRepository();

      eventStore = InMemoryEventStore();
      dispatcher = InMemoryEventDispatcher();

      eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );

      useCase = CompleteMissionUseCase(
        questRepository: repository,
        eventBus: eventBus,
      );

      missionId = MissionId.generate();

      existingQuest = Quest.create(
        id: QuestId.generate(),
        journeyId: JourneyId.generate(),
        title: QuestTitle('Weight Loss Quest'),
      );

      existingQuest.addMission(
        missionId: missionId,
        title: MissionTitle('Walk 20 Minutes'),
      );

      existingQuest.clearDomainEvents();

      await repository.save(existingQuest);
    });

    test('completes mission', () async {
      await useCase.execute(
        CompleteMissionRequest(questId: existingQuest.id, missionId: missionId),
      );

      final updatedQuest = await repository.findById(existingQuest.id);

      expect(updatedQuest!.missions.first.isCompleted, isTrue);
    });

    test('saves updated quest', () async {
      await useCase.execute(
        CompleteMissionRequest(questId: existingQuest.id, missionId: missionId),
      );

      final updatedQuest = await repository.findById(existingQuest.id);

      expect(updatedQuest!.completedMissionCount, 1);
    });

    test('publishes MissionCompleted event', () async {
      await useCase.execute(
        CompleteMissionRequest(questId: existingQuest.id, missionId: missionId),
      );

      final envelopes = await eventStore.allEvents();

      expect(envelopes.any((e) => e.event is MissionCompleted), isTrue);
    });

    test('publishes QuestCompleted when final mission completed', () async {
      await useCase.execute(
        CompleteMissionRequest(questId: existingQuest.id, missionId: missionId),
      );

      final envelopes = await eventStore.allEvents();

      expect(envelopes.any((e) => e.event is QuestCompleted), isTrue);
    });

    test('returns updated quest', () async {
      final result = await useCase.execute(
        CompleteMissionRequest(questId: existingQuest.id, missionId: missionId),
      );

      expect(result, isA<Success<Quest>>());
    });

    test('fails when quest does not exist', () async {
      final result = await useCase.execute(
        CompleteMissionRequest(
          questId: QuestId.generate(),
          missionId: missionId,
        ),
      );

      expect(result, isA<Failure<Quest>>());
    });

    test('fails when mission does not exist', () async {
      final result = await useCase.execute(
        CompleteMissionRequest(
          questId: existingQuest.id,
          missionId: MissionId.generate(),
        ),
      );

      expect(result, isA<Failure<Quest>>());
    });
  });
}
