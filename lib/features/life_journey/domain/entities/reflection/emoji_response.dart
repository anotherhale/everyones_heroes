import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/reflection_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

final class EmojiResponse extends ReflectionResponse {
  const EmojiResponse({required this.emotion});

  final ReflectionEmotion emotion;

  @override
  ReflectionResponseType get type => ReflectionResponseType.emoji;
}
