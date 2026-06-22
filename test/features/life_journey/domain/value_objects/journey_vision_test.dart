import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';

void main() {
  group('JourneyVision', () {
    test('creates valid vision', () {
      final vision = JourneyVision(
        'Become healthy enough to hike with my family',
      );

      expect(vision.value, 'Become healthy enough to hike with my family');
    });

    test('trims whitespace', () {
      final vision = JourneyVision(
        '   Become healthy enough to hike with my family   ',
      );

      expect(vision.value, 'Become healthy enough to hike with my family');
    });

    test('throws when empty', () {
      expect(() => JourneyVision(''), throwsArgumentError);
    });

    test('throws when whitespace only', () {
      expect(() => JourneyVision('     '), throwsArgumentError);
    });

    test('throws when shorter than 3 characters', () {
      expect(() => JourneyVision('To'), throwsArgumentError);
    });

    test('allows exactly 3 characters', () {
      expect(() => JourneyVision('123'), returnsNormally);
    });

    test('throws when longer than 500 characters', () {
      final value = 'a' * 501;

      expect(() => JourneyVision(value), throwsArgumentError);
    });

    test('allows exactly 500 characters', () {
      final value = 'a' * 500;

      expect(() => JourneyVision(value), returnsNormally);
    });

    test('equal when values match', () {
      final first = JourneyVision(
        'Become healthy enough to hike with my family',
      );

      final second = JourneyVision(
        'Become healthy enough to hike with my family',
      );

      expect(first, equals(second));
    });

    test('not equal when values differ', () {
      final first = JourneyVision(
        'Become healthy enough to hike with my family',
      );

      final second = JourneyVision('Run a marathon');

      expect(first, isNot(equals(second)));
    });

    test('hashCodes match for equal values', () {
      final first = JourneyVision(
        'Become healthy enough to hike with my family',
      );

      final second = JourneyVision(
        'Become healthy enough to hike with my family',
      );

      expect(first.hashCode, second.hashCode);
    });

    test('toString returns underlying value', () {
      final vision = JourneyVision(
        'Become healthy enough to hike with my family',
      );

      expect(vision.toString(), 'Become healthy enough to hike with my family');
    });
  });
}
