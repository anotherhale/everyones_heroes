import 'package:eh_platform/src/events/domain_event.dart';

abstract interface class EventBus {
  Future<void> publish(DomainEvent event);
}
