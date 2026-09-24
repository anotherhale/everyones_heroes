import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

/// JSON snapshot mapper for durable [StoryVoiceRendering] persistence.
abstract final class StoryVoiceRenderingSnapshotMapper {
  static Map<String, dynamic> toJson(StoryVoiceRendering rendering) {
    return {
      'id': rendering.id.value,
      'storyId': rendering.storyId.value,
      'experiencePlanId': rendering.experiencePlanId.value,
      'experiencePlanProcessingVersion':
          rendering.experiencePlanProcessingVersion,
      'sourceRepresentationId': rendering.sourceRepresentationId.value,
      'renderingMode': rendering.renderingMode.name,
      'mediaReference': rendering.mediaReference.uri,
      'contentType': rendering.contentType,
      'byteLength': rendering.byteLength,
      'createdAt': rendering.createdAt.toIso8601String(),
      'providerLabel': rendering.providerLabel,
      'modelLabel': rendering.modelLabel,
      'processingVersion': rendering.processingVersion,
      'isAiGenerated': rendering.isAiGenerated,
    };
  }

  static StoryVoiceRendering fromJson(Map<String, dynamic> json) {
    final byteLength = json['byteLength'];
    if (byteLength is! int || byteLength <= 0) {
      throw const FormatException(
        'StoryVoiceRendering.byteLength must be a positive int.',
      );
    }
    final mediaUri = json['mediaReference'] as String?;
    if (mediaUri == null || mediaUri.trim().isEmpty) {
      throw const FormatException(
        'StoryVoiceRendering.mediaReference is required.',
      );
    }

    return StoryVoiceRendering(
      id: StoryVoiceRenderingId(json['id'] as String),
      storyId: StoryId(json['storyId'] as String),
      experiencePlanId: StoryExperiencePlanId(
        json['experiencePlanId'] as String,
      ),
      experiencePlanProcessingVersion:
          json['experiencePlanProcessingVersion'] as String,
      sourceRepresentationId: StoryRepresentationId(
        json['sourceRepresentationId'] as String,
      ),
      renderingMode: VoiceRenderingMode.values.byName(
        json['renderingMode'] as String,
      ),
      mediaReference: MediaReference(mediaUri),
      contentType: json['contentType'] as String,
      byteLength: byteLength,
      createdAt: DateTime.parse(json['createdAt'] as String),
      providerLabel: json['providerLabel'] as String?,
      modelLabel: json['modelLabel'] as String?,
      processingVersion: (json['processingVersion'] as String?) ??
          StoryVoiceRendering.defaultProcessingVersion,
    );
  }
}
