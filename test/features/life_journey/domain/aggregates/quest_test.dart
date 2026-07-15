import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/quest_status.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/mission_completed.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/quest_completed.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/quest_created.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/mission_title.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  Quest createQuest() {
    return Quest.create(
      id: QuestId.generate(),
      journeyId: JourneyId.generate(),
      title: QuestTitle('Become Physically Stronger'),
    );
  }

  group('Quest Creation', () {
    test('creates quest', () {
      final quest = createQuest();

      expect(quest.title, QuestTitle('Become Physically Stronger'));
    });

    test('starts active', () {
      expect(createQuest().status, QuestStatus.active);
    });

    test('starts with no missions', () {
      expect(createQuest().missions, isEmpty);
    });

    test('raises QuestCreated', () {
      final quest = createQuest();
      final events = quest.pullDomainEvents();
      expectEventRaised<QuestCreated>(events);
      expectEventCount(events, 1);
    });
  });

  group('Mission Management', () {
    test('adds mission', () {
      final quest = createQuest();

      quest.addMission(
        missionId: MissionId.generate(),
        title: MissionTitle('Walk 20 Minutes'),
      );

      expect(quest.missionCount, 1);
    });

    test('adds multiple missions', () {
      final quest = createQuest();

      quest.addMission(
        missionId: MissionId.generate(),
        title: MissionTitle('A'),
      );

      quest.addMission(
        missionId: MissionId.generate(),
        title: MissionTitle('B'),
      );

      expect(quest.missionCount, 2);
    });

    test('cannot add duplicate mission ids', () {
      final quest = createQuest();

      final missionId = MissionId.generate();

      quest.addMission(missionId: missionId, title: MissionTitle('A'));

      expect(
        () => quest.addMission(missionId: missionId, title: MissionTitle('B')),
        throwsStateError,
      );
    });
  });

  group('Mission Completion', () {
    test('completes mission', () {
      final quest = createQuest();

      final missionId = MissionId.generate();

      quest.addMission(missionId: missionId, title: MissionTitle('Walk'));

      quest.completeMission(missionId);

      expect(quest.completedMissionCount, 1);
    });

    test('raises MissionCompleted', () {
      final quest = createQuest();
      quest.pullDomainEvents();
      final missionId = MissionId.generate();

      quest.addMission(missionId: missionId, title: MissionTitle('Walk'));
      quest.pullDomainEvents();
      quest.completeMission(missionId);
      final events = quest.pullDomainEvents();
      expectEventRaised<MissionCompleted>(events);
      expectEventCount(events, 2);
    });

    test('cannot complete unknown mission', () {
      final quest = createQuest();

      expect(
        () => quest.completeMission(MissionId.generate()),
        throwsStateError,
      );
    });
  });

  group('Quest Completion', () {
    test('remains active if missions remain', () {
      final quest = createQuest();

      final first = MissionId.generate();

      final second = MissionId.generate();

      quest.addMission(missionId: first, title: MissionTitle('A'));

      quest.addMission(missionId: second, title: MissionTitle('B'));

      quest.completeMission(first);

      expect(quest.status, QuestStatus.active);
    });

    test('completes when all missions complete', () {
      final quest = createQuest();

      final first = MissionId.generate();

      final second = MissionId.generate();

      quest.addMission(missionId: first, title: MissionTitle('A'));

      quest.addMission(missionId: second, title: MissionTitle('B'));

      quest.completeMission(first);
      quest.completeMission(second);

      expect(quest.status, QuestStatus.completed);
    });

    test('raises QuestCompleted', () {
      final quest = createQuest();
      quest.pullDomainEvents();
      final missionId = MissionId.generate();

      quest.addMission(missionId: missionId, title: MissionTitle('Walk'));
      quest.pullDomainEvents();
      quest.completeMission(missionId);
      final events = quest.pullDomainEvents();
      expectEventRaised<MissionCompleted>(events);
      expectEventCount(events, 2);
    });

    test('cannot add mission after completion', () {
      final quest = createQuest();

      final missionId = MissionId.generate();

      quest.addMission(missionId: missionId, title: MissionTitle('Walk'));

      quest.completeMission(missionId);

      expect(
        () => quest.addMission(
          missionId: MissionId.generate(),
          title: MissionTitle('New'),
        ),
        throwsStateError,
      );
    });
  });

  group('Quest Progress', () {
    test('progress is zero when empty', () {
      expect(createQuest().progress, 0);
    });

    test('progress reflects completion', () {
      final quest = createQuest();

      final first = MissionId.generate();

      final second = MissionId.generate();

      quest.addMission(missionId: first, title: MissionTitle('A'));

      quest.addMission(missionId: second, title: MissionTitle('B'));

      quest.completeMission(first);

      expect(quest.progress, 0.5);
    });

    test('progress becomes one when complete', () {
      final quest = createQuest();

      final missionId = MissionId.generate();

      quest.addMission(missionId: missionId, title: MissionTitle('Walk'));

      quest.completeMission(missionId);

      expect(quest.progress, 1.0);
    });
  });

  group('Quest Abandonment', () {
    test('can abandon active quest', () {
      final quest = createQuest();

      quest.abandon();

      expect(quest.status, QuestStatus.abandoned);
    });

    test('cannot abandon completed quest', () {
      final quest = createQuest();

      final missionId = MissionId.generate();

      quest.addMission(missionId: missionId, title: MissionTitle('Walk'));

      quest.completeMission(missionId);

      expect(quest.abandon, throwsStateError);
    });
  });
}
