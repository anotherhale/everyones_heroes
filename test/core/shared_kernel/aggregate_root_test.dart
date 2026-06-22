import 'package:everyonesheroes/core/eventing/domain_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/core/ids/event_id.dart';

final class TestEvent extends DomainEvent {
  @override
  final EventId eventId = EventId.generate();

  @override
  final DateTime occurredAt = DateTime.now();

  @override
  String get aggregateId => '1';

  @override
  String get aggregateType => 'Test';

  @override
  String? get causationId => null;

  @override
  String? get correlationId => null;
}

final class TestAggregate extends AggregateRoot<String> {
  TestAggregate() : super('1');
}

void main() {
  group('AggregateRoot', () {
    test('raises domain event', () {
      final aggregate = TestAggregate();

      aggregate.raise(TestEvent());

      expect(aggregate.domainEvents.length, 1);
    });

    test('clears domain events', () {
      final aggregate = TestAggregate();

      aggregate.raise(TestEvent());

      aggregate.clearDomainEvents();

      expect(aggregate.domainEvents, isEmpty);
    });
  });
}
