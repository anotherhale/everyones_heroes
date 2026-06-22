import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/scale_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScaleResponse', () {
    test('creates response', () {
      final response = ScaleResponse(value: 7);

      expect(response.value, 7);
    });

    test('accepts valid values', () {
      expect(ScaleResponse(value: 0).value, 0);

      expect(ScaleResponse(value: 10).value, 10);
    });

    test('rejects negative values', () {
      expect(() => ScaleResponse(value: -1), throwsArgumentError);
    });

    test('rejects values above max', () {
      expect(() => ScaleResponse(value: 11), throwsArgumentError);
    });

    test('returns scale type', () {
      final response = ScaleResponse(value: 5);

      expect(response.type, ReflectionResponseType.scale);
    });
  });
}
