import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/domain_event.dart';

void expectEventRaised<T extends DomainEvent>(List<DomainEvent> events) {
  expect(
    events.any((event) => event is T),
    isTrue,
    reason: 'Expected event of type $T',
  );
}

void expectNoEventRaised<T extends DomainEvent>(List<DomainEvent> events) {
  expect(
    events.any((event) => event is T),
    isFalse,
    reason: 'Expected no event of type $T',
  );
}

T expectSingleEvent<T extends DomainEvent>(List<DomainEvent> events) {
  final matching = events.whereType<T>().toList(growable: false);

  expect(
    matching,
    hasLength(1),
    reason: 'Expected exactly one event of type $T',
  );

  return matching.single;
}

void expectEventCount(List<DomainEvent> events, int expected) {
  expect(events, hasLength(expected));
}
