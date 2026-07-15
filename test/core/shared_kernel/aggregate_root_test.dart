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
    test('pullDomainEvents returns events only once', () {
      final aggregate = TestAggregate();

      aggregate.raise(TestEvent());

      final firstPull = aggregate.pullDomainEvents();
      final secondPull = aggregate.pullDomainEvents();

      expect(firstPull, hasLength(1));
      expect(secondPull, isEmpty);
    });
  });
}
