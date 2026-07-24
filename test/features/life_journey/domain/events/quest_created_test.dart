import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/quest_created.dart';

void main() {
  group('QuestCreated', () {
    test('stores payload', () {
      final journeyId = JourneyId.generate();

      final event = QuestCreated(aggregateId: journeyId, journeyId: journeyId);

      expect(event.aggregateId, journeyId);

      expect(event.journeyId, journeyId);
    });

    test('uses Quest aggregate type', () {
      final event = QuestCreated(
        aggregateId: QuestId.generate(),
        journeyId: JourneyId.generate(),
      );

      expect(event.aggregateType, AggregateType.quest);
    });
  });
}
