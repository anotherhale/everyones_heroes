import 'package:everyonesheroes/core/eventing/domain_event_reactor.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_event_test.dart';

final class Counterreactor implements DomainEventReactor<TestEvent> {
  int value = 0;

  @override
  Type get eventType => TestEvent;

  @override
  Future<void> react(TestEvent event) async {
    value++;
  }
}

void main() {
  group('Event Pipeline Integration', () {
    test('publish -> store -> dispatch -> reactor', () async {
      final store = InMemoryEventStore();

      final dispatcher = InMemoryEventDispatcher();

      final reactor = Counterreactor();

      dispatcher.register<TestEvent>(reactor);

      final bus = InMemoryEventBus(eventStore: store, dispatcher: dispatcher);

      await bus.publish(TestEvent(aggregateId: '1', aggregateType: 'Journey'));

      final events = await store.allEvents();

      expect(events.length, 1);

      expect(reactor.value, 1);
    });
  });
}
