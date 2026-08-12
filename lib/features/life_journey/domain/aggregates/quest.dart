import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/mission.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/quest_status.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/mission_completed.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/mission_created.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/quest_completed.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/quest_created.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/mission_title.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';

final class Quest extends AggregateRoot<QuestId> {
  Quest({
    required QuestId id,
    required this._journeyId,
    required this._title,
    List<Mission>? missions,
    this._status = QuestStatus.active,
  }) : _missions = missions ?? [],
       super(id);

  final JourneyId _journeyId;

  final QuestTitle _title;

  final List<Mission> _missions;

  QuestStatus _status;

  factory Quest.create({
    required QuestId id,
    required JourneyId journeyId,
    required QuestTitle title,
  }) {
    final quest = Quest(id: id, journeyId: journeyId, title: title);

    quest.raise(QuestCreated(aggregateId: id, journeyId: journeyId));

    return quest;
  }

  JourneyId get journeyId => _journeyId;

  QuestTitle get title => _title;

  QuestStatus get status => _status;

  List<Mission> get missions => List.unmodifiable(_missions);

  bool get isCompleted => _status == QuestStatus.completed;

  bool get isActive => _status == QuestStatus.active;

  int get missionCount => _missions.length;

  int get completedMissionCount => _missions.where((m) => m.isCompleted).length;

  double get progress {
    if (_missions.isEmpty) {
      return 0;
    }

    return completedMissionCount / missionCount;
  }

  void addMission({required MissionId missionId, required MissionTitle title}) {
    if (isCompleted) {
      throw StateError('Cannot add missions to a completed quest.');
    }

    final alreadyExists = _missions.any((mission) => mission.id == missionId);

    if (alreadyExists) {
      throw StateError('Mission already exists in quest.');
    }

    _missions.add(Mission.create(id: missionId, title: title));

    raise(MissionCreated(aggregateId: id, missionId: missionId));
  }

  void completeMission(MissionId missionId) {
    final mission = _missions.where((mission) => mission.id == missionId);

    if (mission.isEmpty) {
      throw StateError('Mission not found.');
    }

    final targetMission = mission.first;

    targetMission.complete();

    raise(MissionCompleted(aggregateId: id, missionId: missionId));

    _evaluateCompletion();
  }

  void abandon() {
    if (isCompleted) {
      throw StateError('Cannot abandon a completed quest.');
    }

    _status = QuestStatus.abandoned;
  }

  void _evaluateCompletion() {
    if (_missions.isEmpty) {
      return;
    }

    final allCompleted = _missions.every((mission) => mission.isCompleted);

    if (!allCompleted) {
      return;
    }

    _status = QuestStatus.completed;

    raise(QuestCompleted(aggregateId: id, journeyId: journeyId));
  }
}
