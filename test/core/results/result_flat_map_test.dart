import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';

void main() {
  group('Result.flatMap', () {
    test('chains success operations', () {
      const result = Success<int>(5);

      final mapped = result.flatMap((x) => Success(x * 10));

      expect(mapped.fold(onSuccess: (v) => v, onFailure: (_) => -1), 50);
    });

    test('propagates failure', () {
      const result = Failure<int>('error');

      final mapped = result.flatMap((x) => Success(x * 10));

      expect(mapped.isFailure, isTrue);
    });
  });
}
