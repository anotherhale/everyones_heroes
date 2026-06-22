import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/shared_kernel/fixed_clock.dart';

void main() {
  group('FixedClock', () {
    test('returns supplied time', () {
      final expected = DateTime(2026, 1, 1, 12, 30);

      final clock = FixedClock(expected);

      expect(clock.now(), expected);
    });

    test('always returns same value', () {
      final expected = DateTime(2026, 1, 1);

      final clock = FixedClock(expected);

      expect(clock.now(), expected);
      expect(clock.now(), expected);
      expect(clock.now(), expected);
    });
  });
}
