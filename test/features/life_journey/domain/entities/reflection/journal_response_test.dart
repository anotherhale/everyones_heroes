import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/journal_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JournalResponse', () {
    test('creates response', () {
      const response = JournalResponse(text: 'Today was difficult.');

      expect(response.text, 'Today was difficult.');
    });

    test('returns journal type', () {
      const response = JournalResponse(text: 'Test');

      expect(response.type, ReflectionResponseType.journal);
    });
  });
}
