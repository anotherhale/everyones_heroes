import 'package:eh_platform/src/events/domain_event.dart';
import 'package:eh_platform/src/events/domain_event_reactor.dart';

abstract interface class EventDispatcher {
  Future<void> dispatch(DomainEvent event);
  void register<T extends DomainEvent>(DomainEventReactor<T> reactor);
}
