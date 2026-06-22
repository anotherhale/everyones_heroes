import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/results/failure.dart';

void main() {
  group('Failure', () {
    test('isSuccess returns false', () {
      const result = Failure<int>('boom');

      expect(result.isSuccess, isFalse);
    });

    test('isFailure returns true', () {
      const result = Failure<int>('boom');

      expect(result.isFailure, isTrue);
    });

    test('getOrElse returns fallback', () {
      const result = Failure<int>('boom');

      expect(result.getOrElse(100), 100);
    });

    test('fold executes failure branch', () {
      const result = Failure<int>('boom');

      final value = result.fold(onSuccess: (v) => v, onFailure: (_) => -1);

      expect(value, -1);
    });
  });
}
