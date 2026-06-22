import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/shared_kernel/system_clock.dart';

void main() {
  group('SystemClock', () {
    test('returns current time', () {
      final before = DateTime.now();

      final clock = SystemClock();

      final result = clock.now();

      final after = DateTime.now();

      expect(
        result.isAfter(before.subtract(const Duration(seconds: 1))) ||
            result.isAtSameMomentAs(before),
        isTrue,
      );

      expect(
        result.isBefore(after.add(const Duration(seconds: 1))) ||
            result.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });
}
