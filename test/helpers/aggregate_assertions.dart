import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';

List<DomainEvent> pullEvents(AggregateRoot aggregate) {
  return aggregate.pullDomainEvents();
}

void expectNoDomainEvents(AggregateRoot aggregate) {
  expect(aggregate.pullDomainEvents(), isEmpty);
}

void expectHasDomainEvents(AggregateRoot aggregate) {
  expect(aggregate.pullDomainEvents(), isNotEmpty);
}

void expectDomainEventCount(AggregateRoot aggregate, int count) {
  expect(aggregate.pullDomainEvents(), hasLength(count));
}
