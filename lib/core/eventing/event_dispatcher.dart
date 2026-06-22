import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/event_handler.dart';

abstract interface class EventDispatcher {
  Future<void> dispatch(DomainEvent event);

  void register<T extends DomainEvent>(EventHandler<T> handler);
}
