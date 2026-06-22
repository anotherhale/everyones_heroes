import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

import 'reflection_response.dart';

final class PromptResponse extends ReflectionResponse {
  PromptResponse({required this.prompt, required this.response}) {
    if (prompt.trim().isEmpty) {
      throw ArgumentError('Prompt cannot be empty.');
    }

    if (response.trim().isEmpty) {
      throw ArgumentError('Response cannot be empty.');
    }
  }

  final String prompt;

  final String response;

  @override
  ReflectionResponseType get type => ReflectionResponseType.prompt;
}
