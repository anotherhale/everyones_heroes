import 'package:everyonesheroes/core/eventing/domain_event.dart';

abstract interface class EventHandler<T extends DomainEvent> {
  Future<void> handle(T event);
}
