import 'package:eh_platform/src/events/domain_event.dart';
import 'package:eh_platform/src/events/event_bus.dart';
import 'package:eh_platform/src/events/event_dispatcher.dart';
import 'package:eh_platform/src/events/event_envelope.dart';
import 'package:eh_platform/src/events/event_store.dart';

/// In-process EventBus: store then deterministic synchronous dispatch.
final class InMemoryEventBus implements EventBus {
  const InMemoryEventBus({
    required this._eventStore,
    required this._dispatcher,
  });

  final EventStore _eventStore;
  final EventDispatcher _dispatcher;

  @override
  Future<void> publish(DomainEvent event) async {
    final envelope = EventEnvelope(
      event: event,
      correlationId: event.correlationId,
      causationId: event.causationId,
    );
    await _eventStore.append(envelope);
    await _dispatcher.dispatch(event);
  }
}
