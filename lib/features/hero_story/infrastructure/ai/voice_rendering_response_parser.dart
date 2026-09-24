import 'dart:convert';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_rendering_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

/// Parses and validates EH AI proxy voice-rendering responses (HS.12.6).
abstract final class VoiceRenderingResponseParser {
  static VoiceRenderingDraft parse(String body) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw VoiceRenderingException(
        'Malformed voice-rendering response: $e',
      );
    }

    if (decoded is! Map) {
      throw const VoiceRenderingException(
        'Voice-rendering response must be a JSON object.',
      );
    }
    final json = Map<String, dynamic>.from(decoded);

    final audioBase64 = (json['audioBase64'] as String?)?.trim() ?? '';
    if (audioBase64.isEmpty) {
      throw const VoiceRenderingException(
        'Voice-rendering response is missing audio.',
      );
    }

    late final Uint8List audioBytes;
    try {
      audioBytes = Uint8List.fromList(base64Decode(audioBase64));
    } on FormatException catch (e) {
      throw VoiceRenderingException(
        'Voice-rendering audioBase64 is malformed: $e',
      );
    }

    if (audioBytes.isEmpty) {
      throw const VoiceRenderingException(
        'Voice-rendering audio is empty.',
      );
    }

    final contentType = (json['contentType'] as String?)?.trim() ?? '';
    if (contentType.isEmpty) {
      throw const VoiceRenderingException(
        'Voice-rendering response is missing contentType.',
      );
    }

    final modeRaw = (json['renderingMode'] as String?)?.trim() ?? '';
    if (modeRaw.isEmpty) {
      throw const VoiceRenderingException(
        'Voice-rendering response is missing renderingMode.',
      );
    }
    late final VoiceRenderingMode mode;
    try {
      mode = VoiceRenderingMode.values.byName(modeRaw);
    } on ArgumentError {
      throw VoiceRenderingException(
        'Unknown voice renderingMode: $modeRaw',
      );
    }

    return VoiceRenderingDraft(
      audioBytes: audioBytes,
      contentType: contentType,
      renderingMode: mode,
      providerLabel: (json['providerLabel'] as String?)?.trim(),
      modelLabel: (json['modelLabel'] as String?)?.trim(),
      processingVersion: (json['processingVersion'] as String?)?.trim().isNotEmpty ==
              true
          ? (json['processingVersion'] as String).trim()
          : StoryVoiceRendering.defaultProcessingVersion,
    );
  }
}
