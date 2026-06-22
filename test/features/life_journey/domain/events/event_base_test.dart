import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/journey_created.dart';

void main() {
  group('EventBase', () {
    test('generates event id', () {
      final event = JourneyCreated(
        aggregateId: JourneyId.generate().value,
      );

      expect(
        event.eventId,
        isNotNull,
      );
    });

    test('generates occurredAt timestamp', () {
      final event = JourneyCreated(
        aggregateId: JourneyId.generate().value,
      );

      expect(
        event.occurredAt,
        isNotNull,
      );

      expect(
        event.occurredAt.isBefore(
          DateTime.now().add(
            const Duration(
              seconds: 1,
            ),
          ),
        ),
        isTrue,
      );
    });

    test('preserves aggregate id', () {
      const aggregateId =
          'journey-123';

      final event = JourneyCreated(
        aggregateId: aggregateId,
      );

      expect(
        event.aggregateId,
        aggregateId,
      );
    });

    test('preserves correlation id', () {
      final event = JourneyCreated(
        aggregateId: 'journey-123',
        correlationId:
            'correlation-123',
      );

      expect(
        event.correlationId,
        'correlation-123',
      );
    });

    test('preserves causation id', () {
      final event = JourneyCreated(
        aggregateId: 'journey-123',
        causationId:
            'causation-123',
      );

      expect(
        event.causationId,
        'causation-123',
      );
    });

    test(
      'preserves correlation and causation ids together',
      () {
        final event = JourneyCreated(
          aggregateId:
              'journey-123',
          correlationId:
              'correlation-123',
          causationId:
              'causation-456',
        );

        expect(
          event.correlationId,
          'correlation-123',
        );

        expect(
          event.causationId,
          'causation-456',
        );
      },
    );

    test(
      'creates unique event ids for separate events',
      () {
        final first =
            JourneyCreated(
          aggregateId:
              'journey-123',
        );

        final second =
            JourneyCreated(
          aggregateId:
              'journey-123',
        );

        expect(
          first.eventId,
          isNot(
            equals(
              second.eventId,
            ),
          ),
        );
      },
    );

    test(
      'creates different timestamps for separate events',
      () async {
        final first =
            JourneyCreated(
          aggregateId:
              'journey-123',
        );

        await Future<void>.delayed(
          const Duration(
            milliseconds: 1,
          ),
        );

        final second =
            JourneyCreated(
          aggregateId:
              'journey-123',
        );

        expect(
          second.occurredAt.isAfter(
            first.occurredAt,
          ),
          isTrue,
        );
      },
    );

    test(
      'event metadata remains immutable after creation',
      () {
        final event =
            JourneyCreated(
          aggregateId:
              'journey-123',
          correlationId:
              'corr-123',
          causationId:
              'cause-123',
        );

        final eventId =
            event.eventId;

        final occurredAt =
            event.occurredAt;

        expect(
          event.eventId,
          eventId,
        );

        expect(
          event.occurredAt,
          occurredAt,
        );

        expect(
          event.correlationId,
          'corr-123',
        );

        expect(
          event.causationId,
          'cause-123',
        );
      },
    );
  });
}