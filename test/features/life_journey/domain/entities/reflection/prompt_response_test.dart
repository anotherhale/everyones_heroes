import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/prompt_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptResponse', () {
    test('creates response', () {
      final response = PromptResponse(
        prompt: 'What did you learn?',
        response: 'Consistency matters.',
      );

      expect(response.prompt, 'What did you learn?');

      expect(response.response, 'Consistency matters.');
    });

    test('requires prompt', () {
      expect(
        () => PromptResponse(prompt: '', response: 'answer'),
        throwsArgumentError,
      );
    });

    test('requires response', () {
      expect(
        () => PromptResponse(prompt: 'question', response: ''),
        throwsArgumentError,
      );
    });

    test('returns prompt type', () {
      final response = PromptResponse(prompt: 'question', response: 'answer');

      expect(response.type, ReflectionResponseType.prompt);
    });
  });
}
