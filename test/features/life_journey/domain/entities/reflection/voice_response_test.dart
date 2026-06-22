import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/voice_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceResponse', () {
    test('creates response', () {
      final response = VoiceResponse(
        transcript: 'I learned a lot.',
        durationSeconds: 30,
      );

      expect(response.transcript, 'I learned a lot.');
    });

    test('requires transcript', () {
      expect(() => VoiceResponse(transcript: ''), throwsArgumentError);
    });

    test('rejects negative duration', () {
      expect(
        () => VoiceResponse(transcript: 'Test', durationSeconds: -1),
        throwsArgumentError,
      );
    });

    test('returns voice type', () {
      final response = VoiceResponse(transcript: 'Test');

      expect(response.type, ReflectionResponseType.voice);
    });
  });
}
