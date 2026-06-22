import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/shared_kernel/entity.dart';

final class TestEntity extends Entity<String> {
  final String name;

  const TestEntity(super.id, this.name);
}

final class DifferentEntity extends Entity<String> {
  const DifferentEntity(super.id);
}

void main() {
  group('Entity', () {
    test('entities with same id are equal', () {
      const left = TestEntity('1', 'Andy');

      const right = TestEntity('1', 'Bob');

      expect(left, equals(right));
    });

    test('entities with different ids are not equal', () {
      const left = TestEntity('1', 'Andy');

      const right = TestEntity('2', 'Andy');

      expect(left, isNot(equals(right)));
    });

    test('entity equality ignores non identity fields', () {
      const left = TestEntity('1', 'Andy');

      const right = TestEntity('1', 'Completely Different');

      expect(left, equals(right));
    });

    test('different entity types are not equal even with same id', () {
      const left = TestEntity('1', 'Andy');

      const right = DifferentEntity('1');

      expect(left, isNot(equals(right)));
    });

    test('equal entities have same hashCode', () {
      const left = TestEntity('1', 'Andy');

      const right = TestEntity('1', 'Bob');

      expect(left.hashCode, equals(right.hashCode));
    });

    test('different ids produce different hashCodes', () {
      const left = TestEntity('1', 'Andy');

      const right = TestEntity('2', 'Andy');

      expect(left.hashCode, isNot(equals(right.hashCode)));
    });

    test('entity is equal to itself', () {
      const entity = TestEntity('1', 'Andy');

      expect(entity, equals(entity));
    });

    test('entity is not equal to null', () {
      const entity = TestEntity('1', 'Andy');

      // ignore: unnecessary_null_comparison
      expect(entity == null, isFalse);
    });

    test('entity is not equal to unrelated object', () {
      const entity = TestEntity('1', 'Andy');

      expect(entity, isNot(equals('1')));
    });
  });
}
