import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/reflection_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

final class JournalResponse extends ReflectionResponse {
  const JournalResponse({
    this.prompt,
    required this.response,
    this.emotion = ReflectionEmotion.neutral,
  });

  final String? prompt;
  final String response;
  final ReflectionEmotion emotion;
  @override
  ReflectionResponseType get type => ReflectionResponseType.journal;
}
