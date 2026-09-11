import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanguageCode', () {
    test('normalizes to lowercase', () {
      expect(LanguageCode('EN').value, 'en');
      expect(LanguageCode('en-US').value, 'en-us');
    });

    test('rejects empty and invalid codes', () {
      expect(() => LanguageCode(''), throwsArgumentError);
      expect(() => LanguageCode('english'), throwsArgumentError);
    });

    test('equality is value based', () {
      expect(LanguageCode('es'), LanguageCode('ES'));
    });
  });
}
