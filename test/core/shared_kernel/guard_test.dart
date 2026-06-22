import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/exceptions/validation_exception.dart';
import 'package:everyonesheroes/core/shared_kernel/guard.dart';

void main() {
  group('Guard', () {
    test('againstNull throws ValidationException', () {
      expect(
        () => Guard.againstNull(null, 'value'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('againstEmpty throws ValidationException', () {
      expect(
        () => Guard.againstEmpty('', 'name'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('againstNegative throws ValidationException', () {
      expect(
        () => Guard.againstNegative(-1, 'count'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('againstNull does not throw for valid value', () {
      expect(() => Guard.againstNull('hello', 'value'), returnsNormally);
    });

    test('againstEmpty does not throw for valid string', () {
      expect(() => Guard.againstEmpty('Andy', 'name'), returnsNormally);
    });

    test('againstNegative does not throw for positive number', () {
      expect(() => Guard.againstNegative(10, 'count'), returnsNormally);
    });
  });
}
