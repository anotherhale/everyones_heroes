import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/strength.dart';

void main() {
  group('Strength', () {
    test('accepts minimum value', () {
      expect(Strength(0.0).value, 0.0);
    });

    test('accepts maximum value', () {
      expect(Strength(1.0).value, 1.0);
    });

    test('accepts middle value', () {
      expect(Strength(0.5).value, 0.5);
    });

    test('throws below minimum', () {
      expect(() => Strength(-0.01), throwsAssertionError);
    });

    test('throws above maximum', () {
      expect(() => Strength(1.01), throwsAssertionError);
    });

    test('equal values compare equal', () {
      expect(Strength(0.75), Strength(0.75));
    });

    test('different values compare unequal', () {
      expect(Strength(0.75), isNot(Strength(0.50)));
    });

    test('hashCode matches equality', () {
      expect(Strength(0.75).hashCode, Strength(0.75).hashCode);
    });

    test('isWeak', () {
      expect(Strength(0.20).isWeak, isTrue);
      expect(Strength(0.20).isModerate, isFalse);
      expect(Strength(0.20).isStrong, isFalse);
    });

    test('isModerate', () {
      expect(Strength(0.50).isWeak, isFalse);
      expect(Strength(0.50).isModerate, isTrue);
      expect(Strength(0.50).isStrong, isFalse);
    });

    test('isStrong', () {
      expect(Strength(0.90).isWeak, isFalse);
      expect(Strength(0.90).isModerate, isFalse);
      expect(Strength(0.90).isStrong, isTrue);
    });
  });
}
