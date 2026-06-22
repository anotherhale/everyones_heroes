import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';

void expectNoDomainEvents(
  AggregateRoot aggregate,
) {
  expect(
    aggregate.domainEvents,
    isEmpty,
  );
}

void expectHasDomainEvents(
  AggregateRoot aggregate,
) {
  expect(
    aggregate.domainEvents,
    isNotEmpty,
  );
}

void expectDomainEventCount(
  AggregateRoot aggregate,
  int count,
) {
  expect(
    aggregate.domainEvents.length,
    count,
  );
}

void expectEventsCleared(
  AggregateRoot aggregate,
) {
  aggregate.clearDomainEvents();

  expect(
    aggregate.domainEvents,
    isEmpty,
  );
}