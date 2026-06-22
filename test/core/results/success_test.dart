import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/results/success.dart';

void main() {
  group('Success', () {
    test('isSuccess returns true', () {
      const result = Success<int>(5);

      expect(result.isSuccess, isTrue);
    });

    test('isFailure returns false', () {
      const result = Success<int>(5);

      expect(result.isFailure, isFalse);
    });

    test('getOrElse returns value', () {
      const result = Success<int>(5);

      expect(result.getOrElse(0), 5);
    });

    test('fold executes success branch', () {
      const result = Success<int>(5);

      final value = result.fold(onSuccess: (v) => v * 2, onFailure: (_) => -1);

      expect(value, 10);
    });
  });
}
