import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/shared_kernel/entity.dart';

abstract base class AggregateRoot<TId> extends Entity<TId> {
  final List<DomainEvent> _domainEvents = [];

  AggregateRoot(super.id);

  List<DomainEvent> get domainEvents => List.unmodifiable(_domainEvents);

  void raise(DomainEvent event) {
    _domainEvents.add(event);
  }

  void clearDomainEvents() {
    _domainEvents.clear();
  }
}
