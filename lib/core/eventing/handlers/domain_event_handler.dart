import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/eventing/event_handler.dart';

abstract base class DomainEventHandler<T extends DomainEvent>
    implements EventHandler<T> {
  Type get eventType;
}
