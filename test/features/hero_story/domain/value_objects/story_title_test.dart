import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryTitle', () {
    test('trims surrounding whitespace', () {
      expect(StoryTitle('  Hello World  ').value, 'Hello World');
    });

    test('rejects empty and whitespace-only values', () {
      expect(() => StoryTitle(''), throwsA(isA<ArgumentError>()));
      expect(() => StoryTitle('   '), throwsA(isA<ArgumentError>()));
      expect(() => StoryTitle('\n\t'), throwsA(isA<ArgumentError>()));
    });

    test('rejects titles longer than 300 characters', () {
      expect(
        () => StoryTitle('a' * 301),
        throwsA(isA<ArgumentError>()),
      );
      expect(StoryTitle('a' * 300).value.length, 300);
    });
  });
}
