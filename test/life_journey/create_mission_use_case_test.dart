import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_quest_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/core/results/failure.dart';

import 'package:everyonesheroes/features/life_journey/application/requests/create_mission_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_mission_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/mission_title.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';

void main() {
  group('CreateMissionUseCase', () {
    late InMemoryQuestRepository repository;
    late InMemoryEventBus eventBus;
    late CreateMissionUseCase useCase;

    late Quest existingQuest;

    setUp(() async {
      final store = InMemoryEventStore();

      final dispatcher = InMemoryEventDispatcher();

      repository = InMemoryQuestRepository();
      eventBus = InMemoryEventBus(eventStore: store, dispatcher: dispatcher);
      useCase = CreateMissionUseCase(
        questRepository: repository,
        eventBus: eventBus,
      );

      existingQuest = Quest.create(
        id: QuestId.generate(),
        journeyId: JourneyId.generate(),
        title: QuestTitle('Weight Loss Quest'),
      );

      existingQuest.clearDomainEvents();

      await repository.save(existingQuest);
    });

    test('adds mission to quest', () async {
      final missionId = MissionId.generate();

      await useCase.execute(
        CreateMissionRequest(
          questId: existingQuest.id,
          missionId: missionId,
          title: MissionTitle('Walk 20 Minutes'),
        ),
      );

      final updatedQuest = await repository.findById(existingQuest.id);

      expect(updatedQuest!.missions.any((m) => m.id == missionId), isTrue);
    });

    test('increments mission count', () async {
      await useCase.execute(
        CreateMissionRequest(
          questId: existingQuest.id,
          missionId: MissionId.generate(),
          title: MissionTitle('Walk 20 Minutes'),
        ),
      );

      final updatedQuest = await repository.findById(existingQuest.id);

      expect(updatedQuest!.missionCount, 1);
    });

    test('saves updated quest', () async {
      final missionId = MissionId.generate();

      await useCase.execute(
        CreateMissionRequest(
          questId: existingQuest.id,
          missionId: missionId,
          title: MissionTitle('Walk 20 Minutes'),
        ),
      );

      final savedQuest = await repository.findById(existingQuest.id);

      expect(savedQuest, isNotNull);

      expect(savedQuest!.missions.length, 1);
    });

    test('returns updated quest', () async {
      final missionId = MissionId.generate();

      final result = await useCase.execute(
        CreateMissionRequest(
          questId: existingQuest.id,
          missionId: missionId,
          title: MissionTitle('Walk 20 Minutes'),
        ),
      );

      result.fold(
        onSuccess: (quest) {
          expect(quest.missions.length, 1);
        },
        onFailure: fail,
      );
    });

    test('fails when quest does not exist', () async {
      final result = await useCase.execute(
        CreateMissionRequest(
          questId: QuestId.generate(),
          missionId: MissionId.generate(),
          title: MissionTitle('Walk 20 Minutes'),
        ),
      );

      expect(result, isA<Failure<Quest>>());
    });
  });
}
