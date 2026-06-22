import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';

void expectEventRaised<T extends DomainEvent>(
  AggregateRoot aggregate,
) {
  expect(
    aggregate.domainEvents.any(
      (event) => event is T,
    ),
    isTrue,
    reason:
        'Expected aggregate to raise event of type $T',
  );
}

void expectNoEventRaised<T extends DomainEvent>(
  AggregateRoot aggregate,
) {
  expect(
    aggregate.domainEvents.any(
      (event) => event is T,
    ),
    isFalse,
    reason:
        'Expected aggregate to not raise event of type $T',
  );
}

T expectSingleEvent<T extends DomainEvent>(
  AggregateRoot aggregate,
) {
  final events = aggregate.domainEvents
      .whereType<T>()
      .toList();

  expect(
    events.length,
    1,
    reason:
        'Expected exactly one event of type $T',
  );

  return events.single;
}

void expectEventCount(
  AggregateRoot aggregate,
  int expected,
) {
  expect(
    aggregate.domainEvents.length,
    expected,
  );
}