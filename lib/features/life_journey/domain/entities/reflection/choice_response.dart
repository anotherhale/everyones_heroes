import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

import 'reflection_response.dart';

final class ChoiceResponse extends ReflectionResponse {
  ChoiceResponse({
    required this.question,
    required this.selectedOption,
    required Iterable<String> options,
  }) : options = List.unmodifiable(options) {
    if (question.trim().isEmpty) {
      throw ArgumentError('Question cannot be empty.');
    }

    if (selectedOption.trim().isEmpty) {
      throw ArgumentError('Selected option cannot be empty.');
    }

    if (!this.options.contains(selectedOption)) {
      throw ArgumentError('Selected option must exist in options.');
    }
  }

  final String question;

  final String selectedOption;

  final List<String> options;

  @override
  ReflectionResponseType get type => ReflectionResponseType.choice;
}
