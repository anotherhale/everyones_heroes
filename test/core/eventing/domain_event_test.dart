import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/ids/event_id.dart';

final class TestEvent extends DomainEvent {
  @override
  final EventId eventId;

  @override
  final DateTime occurredAt;

  @override
  final String aggregateId;

  @override
  final String aggregateType;

  @override
  final String? correlationId;

  @override
  final String? causationId;

  TestEvent({
    required this.aggregateId,
    required this.aggregateType,
    this.correlationId,
    this.causationId,
  }) : eventId = EventId.generate(),
       occurredAt = DateTime.now();
}

void main() {
  group('DomainEvent', () {
    test('event contains id', () {
      final event = TestEvent(aggregateId: '1', aggregateType: 'Journey');

      expect(event.eventId.value.isNotEmpty, isTrue);
    });

    test('event contains timestamp', () {
      final event = TestEvent(aggregateId: '1', aggregateType: 'Journey');

      expect(event.occurredAt, isA<DateTime>());
    });

    test('stores aggregate metadata', () {
      final event = TestEvent(
        aggregateId: 'journey-1',
        aggregateType: 'Journey',
      );

      expect(event.aggregateId, 'journey-1');

      expect(event.aggregateType, 'Journey');
    });

    test('stores correlation metadata', () {
      final event = TestEvent(
        aggregateId: '1',
        aggregateType: 'Journey',
        correlationId: 'corr-1',
        causationId: 'cause-1',
      );

      expect(event.correlationId, 'corr-1');

      expect(event.causationId, 'cause-1');
    });
  });
}
