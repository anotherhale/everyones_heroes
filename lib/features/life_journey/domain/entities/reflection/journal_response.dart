import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/reflection_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

final class JournalResponse extends ReflectionResponse {
  const JournalResponse({required this.text});

  final String text;

  @override
  ReflectionResponseType get type => ReflectionResponseType.journal;
}
