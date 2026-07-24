import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/journey_created.dart';

void main() {
  group('JourneyCreated', () {
    test('stores aggregate id', () {
      final event = JourneyCreated(aggregateId: JourneyId.generate());

      expect(event.aggregateId, isNotNull);
    });

    test('generates event metadata', () {
      final event = JourneyCreated(aggregateId: JourneyId.generate());

      expect(event.eventId, isNotNull);
      expect(event.occurredAt, isNotNull);
      expect(event.aggregateType, isNotNull);
    });

    test('preserves correlation and causation ids', () {
      final event = JourneyCreated(
        aggregateId: JourneyId.generate(),
        correlationId: 'corr-1',
        causationId: 'cause-1',
      );

      expect(event.correlationId, 'corr-1');

      expect(event.causationId, 'cause-1');
    });
  });
}
