import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/event_dispatcher_provider.dart';
import 'package:everyonesheroes/core/eventing/event_store_provider.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventBusProvider =
    Provider<EventBus>((ref) {
  return InMemoryEventBus(
    eventStore: ref.read(
      eventStoreProvider,
    ),
    dispatcher: ref.read(
      eventDispatcherProvider,
    ),
  );
});