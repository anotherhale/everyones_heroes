import 'package:eh_platform/src/eventing/domain_event.dart';

abstract interface class EventBus {
  Future<void> publish(DomainEvent event);
}
