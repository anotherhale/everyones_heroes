import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';

/// JSON snapshot mapper for durable [MusicRendering] persistence.
abstract final class MusicRenderingSnapshotMapper {
  static Map<String, dynamic> toJson(MusicRendering rendering) {
    return {
      'id': rendering.id.value,
      'storyId': rendering.storyId.value,
      'experiencePlanId': rendering.experiencePlanId.value,
      'experiencePlanProcessingVersion':
          rendering.experiencePlanProcessingVersion,
      'mediaReference': rendering.mediaReference.uri,
      'contentType': rendering.contentType,
      'byteLength': rendering.byteLength,
      'durationMs': rendering.duration?.inMilliseconds,
      'createdAt': rendering.createdAt.toIso8601String(),
      'providerLabel': rendering.providerLabel,
      'modelLabel': rendering.modelLabel,
      'generationId': rendering.generationId,
      'promptDigest': rendering.promptDigest,
      'processingVersion': rendering.processingVersion,
      'instrumental': rendering.instrumental,
      'isAiGenerated': rendering.isAiGenerated,
    };
  }

  static MusicRendering fromJson(Map<String, dynamic> json) {
    final byteLength = json['byteLength'];
    if (byteLength is! int || byteLength <= 0) {
      throw const FormatException(
        'MusicRendering.byteLength must be a positive int.',
      );
    }
    final mediaUri = json['mediaReference'] as String?;
    if (mediaUri == null || mediaUri.trim().isEmpty) {
      throw const FormatException(
        'MusicRendering.mediaReference is required.',
      );
    }

    final durationMs = json['durationMs'] as int?;

    return MusicRendering(
      id: MusicRenderingId(json['id'] as String),
      storyId: StoryId(json['storyId'] as String),
      experiencePlanId: StoryExperiencePlanId(
        json['experiencePlanId'] as String,
      ),
      experiencePlanProcessingVersion:
          json['experiencePlanProcessingVersion'] as String,
      mediaReference: MediaReference(mediaUri),
      contentType: json['contentType'] as String,
      byteLength: byteLength,
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
      createdAt: DateTime.parse(json['createdAt'] as String),
      providerLabel: json['providerLabel'] as String?,
      modelLabel: json['modelLabel'] as String?,
      generationId: json['generationId'] as String?,
      promptDigest: json['promptDigest'] as String,
      processingVersion: (json['processingVersion'] as String?) ??
          MusicRendering.defaultProcessingVersion,
      instrumental: json['instrumental'] as bool? ?? true,
    );
  }
}
