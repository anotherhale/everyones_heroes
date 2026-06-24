import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/event_handler.dart';

final class InMemoryEventDispatcher implements EventDispatcher {
  final Map<Type, List<EventHandler<DomainEvent>>> _handlers = {};

  @override
  void register<T extends DomainEvent>(EventHandler<T> handler) {
    _handlers.putIfAbsent(T, () => []);

    _handlers[T]!.add(handler);
  }

  Future<void> unregister<T extends DomainEvent>(
    EventHandler<T> handler,
  ) async {
    _handlers[T]?.remove(handler);
  }

  @override
  Future<void> dispatch(DomainEvent event) async {
    final handlers = _handlers[event.runtimeType];

    if (handlers == null || handlers.isEmpty) {
      return;
    }

    for (final handler in handlers) {
      await handler.handle(event);
    }
  }

  int handlerCount<T extends DomainEvent>() {
    return _handlers[T]?.length ?? 0;
  }
}
