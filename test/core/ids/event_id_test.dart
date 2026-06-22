import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/event_id.dart';

void main() {
  group('EventId', () {
    test('generate creates unique ids', () {
      final first = EventId.generate();

      final second = EventId.generate();

      expect(first, isNot(equals(second)));
    });

    test('generated id has value', () {
      final id = EventId.generate();

      expect(id.value.isNotEmpty, isTrue);
    });
  });
}
