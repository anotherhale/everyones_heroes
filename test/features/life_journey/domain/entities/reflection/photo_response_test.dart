import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/photo_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoResponse', () {
    test('creates response', () {
      final response = PhotoResponse(photoReference: 'photo.jpg');

      expect(response.photoReference, 'photo.jpg');
    });

    test('requires photo reference', () {
      expect(() => PhotoResponse(photoReference: ''), throwsArgumentError);
    });

    test('returns photo type', () {
      final response = PhotoResponse(photoReference: 'photo.jpg');

      expect(response.type, ReflectionResponseType.photo);
    });
  });
}
