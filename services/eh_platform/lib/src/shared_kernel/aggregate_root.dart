import 'package:eh_platform/src/eventing/domain_event.dart';
import 'package:eh_platform/src/shared_kernel/entity.dart';

abstract base class AggregateRoot<TId> extends Entity<TId> {
  final List<DomainEvent> _domainEvents = [];

  AggregateRoot(super.id);

  void raise(DomainEvent event) {
    _domainEvents.add(event);
  }

  void clearDomainEvents() {
    _domainEvents.clear();
  }

  List<DomainEvent> pullDomainEvents() {
    final events = List<DomainEvent>.unmodifiable(_domainEvents);
    _domainEvents.clear();
    return events;
  }
}
