import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

import 'reflection_response.dart';

final class VoiceResponse extends ReflectionResponse {
  VoiceResponse({
    required this.transcript,
    this.durationSeconds,
    this.audioReference,
  }) {
    if (transcript.trim().isEmpty) {
      throw ArgumentError('Transcript cannot be empty.');
    }

    if (durationSeconds != null && durationSeconds! < 0) {
      throw ArgumentError('Duration cannot be negative.');
    }
  }

  final String transcript;

  final int? durationSeconds;

  /// Storage key, URL, blob id, etc.
  final String? audioReference;

  @override
  ReflectionResponseType get type => ReflectionResponseType.voice;
}
