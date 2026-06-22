import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/mission_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/mission_completed.dart';

void main() {
  group('MissionCompleted', () {
    test('stores mission id', () {
      final missionId =
          MissionId.generate();

      final event = MissionCompleted(
        aggregateId: 'quest-123',
        missionId: missionId,
      );

      expect(
        event.missionId,
        missionId,
      );
    });

    test('uses Quest aggregate type', () {
      final event = MissionCompleted(
        aggregateId: 'quest-123',
        missionId:
            MissionId.generate(),
      );

      expect(
        event.aggregateType,
        'Quest',
      );
    });
  });
}