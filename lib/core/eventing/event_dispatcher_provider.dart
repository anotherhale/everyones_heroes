import 'package:everyonesheroes/core/eventing/event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventDispatcherProvider =
    Provider<EventDispatcher>((ref) {
  return InMemoryEventDispatcher();
});