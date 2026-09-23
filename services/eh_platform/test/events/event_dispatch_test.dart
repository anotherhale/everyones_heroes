import 'package:eh_platform/eh_platform.dart';
import 'package:test/test.dart';

final class _RecordingReactor implements DomainEventReactor<PlatformStarted> {
  final List<PlatformStarted> seen = [];

  @override
  Type get eventType => PlatformStarted;

  @override
  Future<void> react(PlatformStarted event) async {
    seen.add(event);
  }
}

void main() {
  group('In-process domain events', () {
    test('stores then dispatches deterministically to reactors', () async {
      final store = InMemoryEventStore();
      final dispatcher = InMemoryEventDispatcher();
      final bus = InMemoryEventBus(eventStore: store, dispatcher: dispatcher);
      final reactor = _RecordingReactor();
      dispatcher.register<PlatformStarted>(reactor);

      final clock = FixedClock(DateTime.utc(2026, 9, 23, 12));
      final event = PlatformStarted(
        eventId: 'evt-1',
        occurredAt: clock.nowUtc(),
        environment: 'test',
        httpPort: 8080,
        correlationId: 'corr-1',
        causationId: 'cause-1',
      );

      await bus.publish(event);

      expect(reactor.seen, hasLength(1));
      expect(reactor.seen.single.eventName, 'PlatformStarted');
      expect(reactor.seen.single.correlationId, 'corr-1');
      expect(reactor.seen.single.causationId, 'cause-1');

      final envelopes = await store.readAll();
      expect(envelopes, hasLength(1));
      expect(envelopes.single.event.eventId, 'evt-1');
    });

    test('dispatch order is registration order', () async {
      final store = InMemoryEventStore();
      final dispatcher = InMemoryEventDispatcher();
      final bus = InMemoryEventBus(eventStore: store, dispatcher: dispatcher);

      final order = <String>[];
      dispatcher.register<PlatformStarted>(_OrderReactor('a', order));
      dispatcher.register<PlatformStarted>(_OrderReactor('b', order));

      await bus.publish(
        PlatformStarted(
          eventId: 'evt-2',
          occurredAt: DateTime.utc(2026, 9, 23),
          environment: 'test',
          httpPort: 1,
        ),
      );

      expect(order, ['a', 'b']);
    });
  });
}

final class _OrderReactor implements DomainEventReactor<PlatformStarted> {
  _OrderReactor(this.label, this.order);

  final String label;
  final List<String> order;

  @override
  Type get eventType => PlatformStarted;

  @override
  Future<void> react(PlatformStarted event) async {
    order.add(label);
  }
}
