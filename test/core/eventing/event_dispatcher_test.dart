import 'package:everyonesheroes/core/eventing/event_handler.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart' hide EventDispatcher;

import 'domain_event_test.dart';

final class CountingHandler implements EventHandler<TestEvent> {
  int count = 0;

  @override
  Future<void> handle(TestEvent event) async {
    count++;
  }
}

void main() {
  group('InMemoryEventDispatcher', () {
    test('dispatches to single handler', () async {
      final dispatcher = InMemoryEventDispatcher();

      final handler = CountingHandler();

      dispatcher.register<TestEvent>(handler);

      await dispatcher.dispatch(
        TestEvent(aggregateId: '1', aggregateType: 'Journey'),
      );

      expect(handler.count, 1);
    });

    test('dispatches to multiple handlers', () async {
      final dispatcher = InMemoryEventDispatcher();

      final first = CountingHandler();

      final second = CountingHandler();

      dispatcher.register<TestEvent>(first);

      dispatcher.register<TestEvent>(second);

      await dispatcher.dispatch(
        TestEvent(aggregateId: '1', aggregateType: 'Journey'),
      );

      expect(first.count, 1);

      expect(second.count, 1);
    });

    test('dispatch with no handlers does not fail', () async {
      final dispatcher = InMemoryEventDispatcher();

      await dispatcher.dispatch(
        TestEvent(aggregateId: '1', aggregateType: 'Journey'),
      );
    });

    test('tracks handler count', () {
      final dispatcher = InMemoryEventDispatcher();

      dispatcher.register<TestEvent>(CountingHandler());

      expect(dispatcher.handlerCount<TestEvent>(), 1);
    });
  });
}
