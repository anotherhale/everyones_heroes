import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

final class TestName extends ValueObject {
  final String value;

  const TestName(this.value);

  @override
  List<Object?> get equalityProps => [value];
}

final class FullName extends ValueObject {
  final String firstName;
  final String lastName;

  const FullName(this.firstName, this.lastName);

  @override
  List<Object?> get equalityProps => [firstName, lastName];
}

void main() {
  group('ValueObject', () {
    test('objects with same value are equal', () {
      const left = TestName('Andy');

      const right = TestName('Andy');

      expect(left, equals(right));
    });

    test('objects with different values are not equal', () {
      const left = TestName('Andy');

      const right = TestName('Bob');

      expect(left, isNot(equals(right)));
    });

    test('equal objects have same hashCode', () {
      const left = TestName('Andy');

      const right = TestName('Andy');

      expect(left.hashCode, right.hashCode);
    });

    test('different objects have different hashCodes', () {
      const left = TestName('Andy');

      const right = TestName('Bob');

      expect(left.hashCode, isNot(right.hashCode));
    });

    test('supports multiple equality properties', () {
      const left = FullName('Andy', 'Smith');

      const right = FullName('Andy', 'Smith');

      expect(left, equals(right));
    });

    test('detects differences in any equality property', () {
      const left = FullName('Andy', 'Smith');

      const right = FullName('Andy', 'Jones');

      expect(left, isNot(equals(right)));
    });

    test('is reflexive', () {
      const value = TestName('Andy');

      expect(value, equals(value));
    });

    test('is symmetric', () {
      const left = TestName('Andy');

      const right = TestName('Andy');

      expect(left == right, right == left);
    });
  });
}
