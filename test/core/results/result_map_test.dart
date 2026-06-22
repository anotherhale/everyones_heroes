import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';

void main() {
  group('Result.map', () {
    test('maps success value', () {
      const result = Success<int>(5);

      final mapped = result.map((x) => x * 2);

      expect(mapped.fold(onSuccess: (v) => v, onFailure: (_) => -1), 10);
    });

    test('failure remains failure', () {
      const result = Failure<int>('error');

      final mapped = result.map((x) => x * 2);

      expect(mapped.isFailure, isTrue);
    });
  });
}
