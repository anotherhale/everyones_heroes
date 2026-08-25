import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/domain_event_reactor.dart';
import 'package:everyonesheroes/core/eventing/event_dispatcher.dart'
    as eventing;
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_event_test.dart';

final class SpyDispatcher implements eventing.EventDispatcher {
  int dispatchCount = 0;

  @override
  Future<void> dispatch(DomainEvent event) async {
    dispatchCount++;
  }

  @override
  void register<T extends DomainEvent>(DomainEventReactor<T> reactor) {}
}

void main() {
  group('InMemoryEventBus', () {
    test('publish stores event', () async {
      final store = InMemoryEventStore();

      final bus = InMemoryEventBus(
        eventStore: store,
        dispatcher: SpyDispatcher(),
      );

      await bus.publish(
        TestEvent(
          aggregateId: JourneyId.generate(),
          aggregateType: AggregateType.journey,
        ),
      );

      final events = await store.allEvents();

      expect(events.length, 1);
    });

    test('publish dispatches event', () async {
      final store = InMemoryEventStore();

      final dispatcher = SpyDispatcher();

      final bus = InMemoryEventBus(eventStore: store, dispatcher: dispatcher);

      await bus.publish(
        TestEvent(
          aggregateId: JourneyId.generate(),
          aggregateType: AggregateType.journey,
        ),
      );

      expect(dispatcher.dispatchCount, 1);
    });
  });
}
