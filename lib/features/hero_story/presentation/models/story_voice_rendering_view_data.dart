import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';

/// What Hero Story shows for a persisted derived voice rendering.
final class StoryVoiceRenderingViewData {
  const StoryVoiceRenderingViewData({
    required this.id,
    required this.experiencePlanId,
    required this.experiencePlanProcessingVersion,
    required this.sourceRepresentationId,
    required this.renderingMode,
    required this.contentType,
    required this.byteLength,
    required this.createdAt,
    this.providerLabel,
    this.modelLabel,
  });

  final StoryVoiceRenderingId id;
  final String experiencePlanId;
  final String experiencePlanProcessingVersion;
  final String sourceRepresentationId;
  final VoiceRenderingMode renderingMode;
  final String contentType;
  final int byteLength;
  final DateTime createdAt;
  final String? providerLabel;
  final String? modelLabel;

  String get modeLabel => switch (renderingMode) {
        VoiceRenderingMode.syntheticNarration => 'Synthetic narration',
        VoiceRenderingMode.heroVoiceTransformation =>
          'Hero voice transformation',
        VoiceRenderingMode.voiceClone => 'Voice clone',
      };
}
