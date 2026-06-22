import 'package:everyonesheroes/core/eventing/event_handler.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_event_test.dart';

final class CounterHandler implements EventHandler<TestEvent> {
  int value = 0;

  @override
  Future<void> handle(TestEvent event) async {
    value++;
  }
}

void main() {
  group('Event Pipeline Integration', () {
    test('publish -> store -> dispatch -> handler', () async {
      final store = InMemoryEventStore();

      final dispatcher = InMemoryEventDispatcher();

      final handler = CounterHandler();

      dispatcher.register<TestEvent>(handler);

      final bus = InMemoryEventBus(eventStore: store, dispatcher: dispatcher);

      await bus.publish(TestEvent(aggregateId: '1', aggregateType: 'Journey'));

      final events = await store.allEvents();

      expect(events.length, 1);

      expect(handler.value, 1);
    });
  });
}
