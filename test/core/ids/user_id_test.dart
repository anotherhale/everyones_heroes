import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/user_id.dart';

void main() {
  group('UserId', () {
    test('generate creates unique ids', () {
      final first = UserId.generate();

      final second = UserId.generate();

      expect(first, isNot(equals(second)));
    });

    test('generated id has value', () {
      final id = UserId.generate();

      expect(id.value.isNotEmpty, isTrue);
    });
  });
}
