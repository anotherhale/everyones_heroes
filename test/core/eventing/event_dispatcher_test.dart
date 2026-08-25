import 'package:everyonesheroes/core/eventing/domain_event_reactor.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:flutter_test/flutter_test.dart' hide EventDispatcher;

import 'domain_event_test.dart';

final class Countingreactor implements DomainEventReactor<TestEvent> {
  int count = 0;

  @override
  Type get eventType => TestEvent;

  @override
  Future<void> react(TestEvent event) async {
    count++;
  }
}

void main() {
  group('InMemoryEventDispatcher', () {
    test('dispatches to single reactor', () async {
      final dispatcher = InMemoryEventDispatcher();

      final reactor = Countingreactor();

      dispatcher.register<TestEvent>(reactor);

      await dispatcher.dispatch(
        TestEvent(
          aggregateId: JourneyId.generate(),
          aggregateType: AggregateType.journey,
        ),
      );

      expect(reactor.count, 1);
    });

    test('dispatches to multiple reactors', () async {
      final dispatcher = InMemoryEventDispatcher();

      final first = Countingreactor();

      final second = Countingreactor();

      dispatcher.register<TestEvent>(first);

      dispatcher.register<TestEvent>(second);

      await dispatcher.dispatch(
        TestEvent(
          aggregateId: JourneyId.generate(),
          aggregateType: AggregateType.journey,
        ),
      );

      expect(first.count, 1);

      expect(second.count, 1);
    });

    test('dispatch with no reactors does not fail', () async {
      final dispatcher = InMemoryEventDispatcher();

      await dispatcher.dispatch(
        TestEvent(
          aggregateId: JourneyId.generate(),
          aggregateType: AggregateType.journey,
        ),
      );
    });

    test('tracks reactor count', () {
      final dispatcher = InMemoryEventDispatcher();

      dispatcher.register<TestEvent>(Countingreactor());

      expect(dispatcher.reactorCount<TestEvent>(), 1);
    });
  });
}
