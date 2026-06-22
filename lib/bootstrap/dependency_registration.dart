import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';

final class DependencyRegistration {
  static InMemoryEventStore? _eventStore;
  static InMemoryEventDispatcher? _dispatcher;
  static InMemoryEventBus? _eventBus;

  static InMemoryEventStore get eventStore => _eventStore!;

  static InMemoryEventDispatcher get dispatcher => _dispatcher!;

  static InMemoryEventBus get eventBus => _eventBus!;

  static void register() {
    if (_eventStore != null) {
      return;
    }

    _eventStore = InMemoryEventStore();

    _dispatcher = InMemoryEventDispatcher();

    _eventBus = InMemoryEventBus(
      eventStore: _eventStore!,
      dispatcher: _dispatcher!,
    );
  }
}
