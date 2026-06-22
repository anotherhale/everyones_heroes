import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/choice_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChoiceResponse', () {
    test('creates response', () {
      final response = ChoiceResponse(
        question: 'What was hardest?',
        selectedOption: 'Consistency',
        options: const ['Starting', 'Consistency', 'Time'],
      );

      expect(response.selectedOption, 'Consistency');
    });

    test('requires question', () {
      expect(
        () => ChoiceResponse(
          question: '',
          selectedOption: 'A',
          options: const ['A'],
        ),
        throwsArgumentError,
      );
    });

    test('requires selected option', () {
      expect(
        () => ChoiceResponse(
          question: 'Q',
          selectedOption: '',
          options: const ['A'],
        ),
        throwsArgumentError,
      );
    });

    test('selected option must exist', () {
      expect(
        () => ChoiceResponse(
          question: 'Q',
          selectedOption: 'B',
          options: const ['A'],
        ),
        throwsArgumentError,
      );
    });

    test('returns choice type', () {
      final response = ChoiceResponse(
        question: 'Q',
        selectedOption: 'A',
        options: const ['A'],
      );

      expect(response.type, ReflectionResponseType.choice);
    });
  });
}
