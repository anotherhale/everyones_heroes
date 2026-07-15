import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/domain_event_reactor.dart';

abstract interface class EventDispatcher {
  Future<void> dispatch(DomainEvent event);

  void register<T extends DomainEvent>(DomainEventReactor<T> reactor);
}
