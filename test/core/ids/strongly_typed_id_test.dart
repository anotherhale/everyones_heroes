import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';

void main() {
  group('StronglyTypedId', () {
    test('ids with same value are equal', () {
      const left = JourneyId('journey-1');

      const right = JourneyId('journey-1');

      expect(left, equals(right));
    });

    test('ids with different values are not equal', () {
      const left = JourneyId('journey-1');

      const right = JourneyId('journey-2');

      expect(left, isNot(equals(right)));
    });

    test('hashCode matches for equal ids', () {
      const left = JourneyId('journey-1');

      const right = JourneyId('journey-1');

      expect(left.hashCode, right.hashCode);
    });

    test('toString returns underlying value', () {
      const id = JourneyId('journey-1');

      expect(id.toString(), 'journey-1');
    });
  });
}
