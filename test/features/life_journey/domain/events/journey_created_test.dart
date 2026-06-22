import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/journey_created.dart';

void main() {
  group('JourneyCreated', () {
    test('stores aggregate id', () {
      final event = JourneyCreated(
        aggregateId: 'journey-123',
      );

      expect(
        event.aggregateId,
        'journey-123',
      );
    });

    test('generates event metadata', () {
      final event = JourneyCreated(
        aggregateId: 'journey-123',
      );

      expect(event.eventId, isNotNull);
      expect(event.occurredAt, isNotNull);
      expect(event.aggregateType, 'Journey');
    });

    test('preserves correlation and causation ids', () {
      final event = JourneyCreated(
        aggregateId: 'journey-123',
        correlationId: 'corr-1',
        causationId: 'cause-1',
      );

      expect(
        event.correlationId,
        'corr-1',
      );

      expect(
        event.causationId,
        'cause-1',
      );
    });
  });
}