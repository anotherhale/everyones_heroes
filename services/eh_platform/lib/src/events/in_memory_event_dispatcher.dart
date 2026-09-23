import 'package:eh_platform/src/events/domain_event.dart';
import 'package:eh_platform/src/events/domain_event_reactor.dart';
import 'package:eh_platform/src/events/event_dispatcher.dart';

/// Deterministic, ordered, in-process reactor dispatch (no Kafka).
final class InMemoryEventDispatcher implements EventDispatcher {
  final Map<Type, List<DomainEventReactor<DomainEvent>>> _reactors = {};

  @override
  void register<T extends DomainEvent>(DomainEventReactor<T> reactor) {
    _reactors.putIfAbsent(T, () => <DomainEventReactor<DomainEvent>>[]);
    _reactors[T]!.add(reactor as DomainEventReactor<DomainEvent>);
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

  int reactorCount<T extends DomainEvent>() => _reactors[T]?.length ?? 0;
}
