import 'dart:typed_data';

import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';

/// Provider-independent Story voice-rendering boundary (HS.12.6).
///
/// Separate from [StoryTranscriptionPort], [CapturedStoryReadingPort], and
/// [StoryExperiencePlannerPort]. Accepts the minimum presentation inputs —
/// never entire domain aggregates.
///
/// Flutter must not call commercial TTS vendors directly; adapters talk to
/// the EH AI proxy only.
abstract interface class VoiceRenderingPort {
  Future<VoiceRenderingDraft> render(VoiceRenderingRequest request);
}

/// Minimum inputs required to render an already-approved presentation.
final class VoiceRenderingRequest {
  const VoiceRenderingRequest({
    required this.storyId,
    required this.experiencePlanId,
    required this.experiencePlanProcessingVersion,
    required this.sourceRepresentationId,
    required this.sourceText,
    required this.renderingMode,
    this.processingVersion,
  });

  final StoryId storyId;
  final StoryExperiencePlanId experiencePlanId;
  final String experiencePlanProcessingVersion;
  final StoryRepresentationId sourceRepresentationId;
  final String sourceText;
  final VoiceRenderingMode renderingMode;
  final String? processingVersion;
}

/// EH-owned draft mapped into a persisted [StoryVoiceRendering] by the use case.
final class VoiceRenderingDraft {
  const VoiceRenderingDraft({
    required this.audioBytes,
    required this.contentType,
    required this.renderingMode,
    this.providerLabel,
    this.modelLabel,
    this.processingVersion,
  });

  final Uint8List audioBytes;
  final String contentType;
  final VoiceRenderingMode renderingMode;
  final String? providerLabel;
  final String? modelLabel;
  final String? processingVersion;
}

final class VoiceRenderingException implements Exception {
  const VoiceRenderingException(this.message);

  final String message;

  @override
  String toString() => 'VoiceRenderingException: $message';
}
