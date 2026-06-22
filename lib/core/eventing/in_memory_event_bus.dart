import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/event_envelope.dart';
import 'package:everyonesheroes/core/eventing/event_store.dart';

final class InMemoryEventBus implements EventBus {
  final EventStore _eventStore;

  final EventDispatcher _dispatcher;

  const InMemoryEventBus({
    required EventStore eventStore,
    required EventDispatcher dispatcher,
  }) : _eventStore = eventStore,
       _dispatcher = dispatcher;

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
