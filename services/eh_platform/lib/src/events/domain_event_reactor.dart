import 'package:eh_platform/src/events/domain_event.dart';

/// Application-layer reactor subscribed to a typed domain event.
abstract interface class DomainEventReactor<T extends DomainEvent> {
  Type get eventType;
  Future<void> react(T event);
}
