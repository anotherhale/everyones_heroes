import 'dart:convert';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/services/music_generation_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';

/// Parses and validates EH AI proxy music-generation responses (Experiment A).
abstract final class MusicGenerationResponseParser {
  static MusicGenerationDraft parse(String body) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw MusicGenerationException(
        'Malformed music-generation response: $e',
      );
    }

    if (decoded is! Map) {
      throw const MusicGenerationException(
        'Music-generation response must be a JSON object.',
      );
    }
    final json = Map<String, dynamic>.from(decoded);

    final audioBase64 = (json['audioBase64'] as String?)?.trim() ?? '';
    if (audioBase64.isEmpty) {
      throw const MusicGenerationException(
        'Music-generation response is missing audio.',
      );
    }

    late final Uint8List audioBytes;
    try {
      audioBytes = Uint8List.fromList(base64Decode(audioBase64));
    } on FormatException catch (e) {
      throw MusicGenerationException(
        'Music-generation audioBase64 is malformed: $e',
      );
    }
    if (audioBytes.isEmpty) {
      throw const MusicGenerationException(
        'Music-generation audio is empty.',
      );
    }

    final contentType = (json['contentType'] as String?)?.trim() ?? '';
    if (contentType.isEmpty) {
      throw const MusicGenerationException(
        'Music-generation response is missing contentType.',
      );
    }

    Duration? duration;
    final durationSeconds = json['durationSeconds'];
    if (durationSeconds is num && durationSeconds > 0) {
      duration = Duration(seconds: durationSeconds.round());
    }

    return MusicGenerationDraft(
      audioBytes: audioBytes,
      contentType: contentType,
      duration: duration,
      providerLabel: (json['providerLabel'] as String?)?.trim(),
      modelLabel: (json['modelLabel'] as String?)?.trim(),
      generationId: (json['generationId'] as String?)?.trim(),
      promptUsed: (json['promptUsed'] as String?)?.trim(),
      processingVersion:
          (json['processingVersion'] as String?)?.trim().isNotEmpty == true
              ? (json['processingVersion'] as String).trim()
              : MusicRendering.defaultProcessingVersion,
      instrumental: json['instrumental'] is bool
          ? json['instrumental'] as bool
          : true,
    );
  }
}
