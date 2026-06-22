import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/event_envelope.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';

import 'domain_event_test.dart';

void main() {
  group('InMemoryEventStore', () {
    test('starts empty', () async {
      final store = InMemoryEventStore();

      final events = await store.allEvents();

      expect(events, isEmpty);
    });

    test('appends event', () async {
      final store = InMemoryEventStore();

      final envelope = EventEnvelope(
        event: TestEvent(aggregateId: '1', aggregateType: 'Journey'),
      );

      await store.append(envelope);

      final events = await store.allEvents();

      expect(events.length, 1);
    });

    test('preserves order', () async {
      final store = InMemoryEventStore();

      final first = EventEnvelope(
        event: TestEvent(aggregateId: '1', aggregateType: 'Journey'),
      );

      final second = EventEnvelope(
        event: TestEvent(aggregateId: '2', aggregateType: 'Journey'),
      );

      await store.append(first);
      await store.append(second);

      final events = await store.allEvents();

      expect(identical(events[0], first), isTrue);

      expect(identical(events[1], second), isTrue);
    });
  });
}
