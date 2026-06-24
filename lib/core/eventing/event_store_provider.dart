import 'package:everyonesheroes/core/eventing/event_store.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventStoreProvider =
    Provider<EventStore>((ref) {
  return InMemoryEventStore();
});