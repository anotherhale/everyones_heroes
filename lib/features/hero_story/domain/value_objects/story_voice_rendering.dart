import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Derived AI voice presentation of an owned Story experience (HS.12.6).
///
/// Persisted separately from the canonical [Story], original recording,
/// transcript, [CapturedStoryReading], and [StoryExperiencePlan].
///
/// AI-generated audio is a presentation artifact — never the source of truth
/// for story content, and never behavioral or psychological evidence.
final class StoryVoiceRendering extends ValueObject {
  StoryVoiceRendering({
    required this.id,
    required this.storyId,
    required this.experiencePlanId,
    required String experiencePlanProcessingVersion,
    required this.sourceRepresentationId,
    required this.renderingMode,
    required this.mediaReference,
    required String contentType,
    required this.byteLength,
    required this.createdAt,
    String? providerLabel,
    String? modelLabel,
    String processingVersion = defaultProcessingVersion,
  })  : experiencePlanProcessingVersion =
            experiencePlanProcessingVersion.trim(),
        contentType = contentType.trim(),
        providerLabel = _trimOrNull(providerLabel),
        modelLabel = _trimOrNull(modelLabel),
        processingVersion = processingVersion.trim() {
    if (this.contentType.isEmpty) {
      throw ArgumentError('contentType cannot be empty.');
    }
    if (byteLength <= 0) {
      throw ArgumentError('byteLength must be positive.');
    }
    if (this.processingVersion.isEmpty) {
      throw ArgumentError('processingVersion cannot be blank.');
    }
    if (this.experiencePlanProcessingVersion.isEmpty) {
      throw ArgumentError('experiencePlanProcessingVersion cannot be blank.');
    }
  }

  static const String defaultProcessingVersion = 'hs12.6.v1';

  /// Supported v1 rendering mode. Other [VoiceRenderingMode] values are
  /// rejected until a later slice establishes their consent and providers.
  static const VoiceRenderingMode supportedMode =
      VoiceRenderingMode.syntheticNarration;

  final StoryVoiceRenderingId id;
  final StoryId storyId;
  final StoryExperiencePlanId experiencePlanId;
  final String experiencePlanProcessingVersion;
  final StoryRepresentationId sourceRepresentationId;
  final VoiceRenderingMode renderingMode;
  final MediaReference mediaReference;
  final String contentType;
  final int byteLength;
  final DateTime createdAt;
  final String? providerLabel;
  final String? modelLabel;
  final String processingVersion;

  bool get isAiGenerated => true;

  bool get isSyntheticNarration =>
      renderingMode == VoiceRenderingMode.syntheticNarration;

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  List<Object?> get equalityProps => [
        id,
        storyId,
        experiencePlanId,
        experiencePlanProcessingVersion,
        sourceRepresentationId,
        renderingMode,
        mediaReference,
        contentType,
        byteLength,
        createdAt,
        providerLabel,
        modelLabel,
        processingVersion,
      ];
}
