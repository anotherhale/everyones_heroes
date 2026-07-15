import 'package:everyonesheroes/core/eventing/domain_event.dart';

abstract interface class DomainEventReactor<T extends DomainEvent> {
  Type get eventType;

  Future<void> react(T event);
}
