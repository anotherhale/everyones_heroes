import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/mission_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/entities/mission.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/mission_status.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/mission_title.dart';

void main() {
  group('Mission Creation', () {
    test('creates mission', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      expect(
        mission.title,
        MissionTitle(
          'Walk for 20 minutes',
        ),
      );
    });

    test('starts pending', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      expect(
        mission.status,
        MissionStatus.pending,
      );
    });

    test('starts incomplete', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      expect(
        mission.isCompleted,
        isFalse,
      );
    });

    test('starts with null completedAt', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      expect(
        mission.completedAt,
        isNull,
      );
    });
  });

  group('Mission Completion', () {
    test('can complete mission', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      mission.complete();

      expect(
        mission.isCompleted,
        isTrue,
      );
    });

    test('status becomes completed', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      mission.complete();

      expect(
        mission.status,
        MissionStatus.completed,
      );
    });

    test('completedAt is populated', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      mission.complete();

      expect(
        mission.completedAt,
        isNotNull,
      );
    });

    test('completedAt is after creation time', () {
      final before = DateTime.now();

      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      mission.complete();

      expect(
        mission.completedAt!.isAfter(
              before.subtract(
                const Duration(
                  milliseconds: 1,
                ),
              ),
            ),
        isTrue,
      );
    });
  });

  group('Mission Invariants', () {
    test('cannot complete twice', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      mission.complete();

      expect(
        mission.complete,
        throwsStateError,
      );
    });

    test('completion timestamp does not change after failure', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      mission.complete();

      final firstTimestamp =
          mission.completedAt;

      expect(
        () => mission.complete(),
        throwsStateError,
      );

      expect(
        mission.completedAt,
        firstTimestamp,
      );
    });

    test('remains completed after failed second completion', () {
      final mission = Mission.create(
        id: MissionId.generate(),
        title: MissionTitle(
          'Walk for 20 minutes',
        ),
      );

      mission.complete();

      expect(
        () => mission.complete(),
        throwsStateError,
      );

      expect(
        mission.status,
        MissionStatus.completed,
      );
    });
  });
}