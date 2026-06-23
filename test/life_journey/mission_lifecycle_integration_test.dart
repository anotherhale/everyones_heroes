import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_quest_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/features/life_journey/application/requests/create_journey_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_journey_use_case.dart';

import 'package:everyonesheroes/features/life_journey/application/requests/create_quest_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_quest_use_case.dart';

import 'package:everyonesheroes/features/life_journey/application/requests/create_mission_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_mission_use_case.dart';

import 'package:everyonesheroes/features/life_journey/application/requests/complete_mission_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/complete_mission_use_case.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/journey_created.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/mission_completed.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/mission_created.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/quest_completed.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/quest_created.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/mission_title.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';

void main() {
  group('Mission Lifecycle Integration', () {
    late InMemoryJourneyRepository journeyRepository;
    late InMemoryQuestRepository questRepository;

    late InMemoryEventStore eventStore;
    late InMemoryEventDispatcher dispatcher;
    late InMemoryEventBus eventBus;

    late CreateJourneyUseCase createJourneyUseCase;
    late CreateQuestUseCase createQuestUseCase;
    late CreateMissionUseCase createMissionUseCase;
    late CompleteMissionUseCase completeMissionUseCase;

    setUp(() {
      journeyRepository = InMemoryJourneyRepository();

      questRepository = InMemoryQuestRepository();

      eventStore = InMemoryEventStore();

      dispatcher = InMemoryEventDispatcher();

      eventBus = InMemoryEventBus(
        eventStore: eventStore,
        dispatcher: dispatcher,
      );

      createJourneyUseCase = CreateJourneyUseCase(
        journeyRepository: journeyRepository,
        eventBus: eventBus,
      );

      createQuestUseCase = CreateQuestUseCase(
        journeyRepository: journeyRepository,
        questRepository: questRepository,
        eventBus: eventBus,
      );

      createMissionUseCase = CreateMissionUseCase(
        questRepository: questRepository,
        eventBus: eventBus,
      );

      completeMissionUseCase = CompleteMissionUseCase(
        questRepository: questRepository,
        eventBus: eventBus,
      );
    });

    test('journey -> quest -> mission -> completion lifecycle', () async {
      final journeyId = JourneyId.generate();
      final questId = QuestId.generate();
      final missionId = MissionId.generate();

      //
      // Create Journey
      //

      await createJourneyUseCase.execute(
        CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision('Become healthier'),
        ),
      );

      //
      // Create Quest
      //

      await createQuestUseCase.execute(
        CreateQuestRequest(
          questId: questId,
          journeyId: journeyId,
          title: QuestTitle('Weight Loss Quest'),
        ),
      );

      //
      // Create Mission
      //

      await createMissionUseCase.execute(
        CreateMissionRequest(
          questId: questId,
          missionId: missionId,
          title: MissionTitle('Walk 20 Minutes'),
        ),
      );

      //
      // Complete Mission
      //

      await completeMissionUseCase.execute(
        CompleteMissionRequest(questId: questId, missionId: missionId),
      );

      //
      // Validate Aggregate State
      //

      final journey = await journeyRepository.findById(journeyId);

      expect(journey, isNotNull);

      expect(journey!.activeQuestIds, contains(questId));

      final quest = await questRepository.findById(questId);

      expect(quest, isNotNull);

      expect(quest!.missionCount, 1);

      expect(quest.completedMissionCount, 1);

      expect(quest.isCompleted, isTrue);

      //
      // Validate Event Pipeline
      //

      final envelopes = await eventStore.allEvents();

      expect(envelopes.any((e) => e.event is JourneyCreated), isTrue);

      expect(envelopes.any((e) => e.event is QuestCreated), isTrue);

      expect(envelopes.any((e) => e.event is MissionCreated), isTrue);

      expect(envelopes.any((e) => e.event is MissionCompleted), isTrue);

      expect(envelopes.any((e) => e.event is QuestCompleted), isTrue);
    });
  });
}
