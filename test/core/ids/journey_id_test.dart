import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';

void main() {
  group('JourneyId', () {
    test('generate creates unique ids', () {
      final first = JourneyId.generate();

      final second = JourneyId.generate();

      expect(first, isNot(equals(second)));
    });

    test('generated id has value', () {
      final id = JourneyId.generate();

      expect(id.value.isNotEmpty, isTrue);
    });
  });
}
