import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/mission_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/mission_completed.dart';

void main() {
  group('MissionCompleted', () {
    test('stores mission id', () {
      final missionId = MissionId.generate();

      final event = MissionCompleted(
        aggregateId: missionId,
        missionId: missionId,
      );

      expect(event.missionId, missionId);
    });

    test('uses Quest aggregate type', () {
      final event = MissionCompleted(
        aggregateId: MissionId.generate(),
        missionId: MissionId.generate(),
      );

      expect(event.aggregateType, AggregateType.quest);
    });
  });
}
