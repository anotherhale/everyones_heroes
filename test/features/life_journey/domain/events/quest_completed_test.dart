import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/quest_completed.dart';

void main() {
  group('QuestCompleted', () {
    test('stores journey id', () {
      final journeyId = JourneyId.generate();

      final event = QuestCompleted(
        aggregateId: QuestId.generate(),
        journeyId: journeyId,
      );

      expect(event.journeyId, journeyId);
    });

    test('uses Quest aggregate type', () {
      final event = QuestCompleted(
        aggregateId: QuestId.generate(),
        journeyId: JourneyId.generate(),
      );

      expect(event.aggregateType, AggregateType.quest);
    });
  });
}
