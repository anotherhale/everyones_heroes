import 'package:everyonesheroes/core/eventing/event_dispatcher_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'event_bus.dart';
import 'event_store.dart';
import 'in_memory_event_bus.dart';
import 'in_memory_event_store.dart';

final eventStoreProvider = Provider<EventStore>((ref) {
  return InMemoryEventStore();
});

final eventBusProvider = Provider<EventBus>((ref) {
  return InMemoryEventBus(
    eventStore: ref.read(eventStoreProvider),
    dispatcher: ref.read(eventDispatcherProvider),
  );
});