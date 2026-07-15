import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/domain_event_reactor.dart';
import 'package:everyonesheroes/core/eventing/event_dispatcher.dart';

final class InMemoryEventDispatcher implements EventDispatcher {
  final Map<Type, List<DomainEventReactor<DomainEvent>>> _reactors = {};

  @override
  void register<T extends DomainEvent>(DomainEventReactor<T> reactor) {
    _reactors.putIfAbsent(T, () => []);

    _reactors[T]!.add(reactor);
  }

  Future<void> unregister<T extends DomainEvent>(
    DomainEventReactor<T> reactor,
  ) async {
    _reactors[T]?.remove(reactor);
  }

  @override
  Future<void> dispatch(DomainEvent event) async {
    final reactors = _reactors[event.runtimeType];

    if (reactors == null || reactors.isEmpty) {
      return;
    }

    for (final reactor in reactors) {
      await reactor.react(event);
    }
  }

  int reactorCount<T extends DomainEvent>() {
    return _reactors[T]?.length ?? 0;
  }
}
