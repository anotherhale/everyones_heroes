import 'package:everyonesheroes/core/eventing/domain_event.dart';

abstract interface class EventBus {
  Future<void> publish(DomainEvent event);
}
