import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmojiResponse', () {
    test('creates response', () {
      const response = EmojiResponse(emotion: ReflectionEmotion.proud);

      expect(response.emotion, ReflectionEmotion.proud);
    });

    test('returns emoji type', () {
      const response = EmojiResponse(emotion: ReflectionEmotion.excited);

      expect(response.type, ReflectionResponseType.emoji);
    });
  });
}
