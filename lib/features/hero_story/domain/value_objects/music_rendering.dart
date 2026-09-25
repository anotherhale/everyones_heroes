import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Derived AI music presentation artifact (Experiment A).
///
/// Persisted separately from the canonical Story, CapturedStoryReading, and
/// StoryExperiencePlan. Never mutates those artifacts. Strategy A: one
/// instrumental bed — not multi-clip stitching.
final class MusicRendering extends ValueObject {
  MusicRendering({
    required this.id,
    required this.storyId,
    required this.experiencePlanId,
    required String experiencePlanProcessingVersion,
    required this.mediaReference,
    required String contentType,
    required this.byteLength,
    required this.createdAt,
    required String promptDigest,
    this.duration,
    String? providerLabel,
    String? modelLabel,
    String? generationId,
    String processingVersion = defaultProcessingVersion,
    this.instrumental = true,
  })  : experiencePlanProcessingVersion =
            experiencePlanProcessingVersion.trim(),
        contentType = contentType.trim(),
        promptDigest = promptDigest.trim(),
        providerLabel = _trimOrNull(providerLabel),
        modelLabel = _trimOrNull(modelLabel),
        generationId = _trimOrNull(generationId),
        processingVersion = processingVersion.trim() {
    if (this.contentType.isEmpty) {
      throw ArgumentError('contentType cannot be empty.');
    }
    if (byteLength <= 0) {
      throw ArgumentError('byteLength must be positive.');
    }
    if (this.promptDigest.isEmpty) {
      throw ArgumentError('promptDigest cannot be blank.');
    }
    if (this.processingVersion.isEmpty) {
      throw ArgumentError('processingVersion cannot be blank.');
    }
    if (this.experiencePlanProcessingVersion.isEmpty) {
      throw ArgumentError('experiencePlanProcessingVersion cannot be blank.');
    }
  }

  static const String defaultProcessingVersion = 'exp-a.music.v1';

  final MusicRenderingId id;
  final StoryId storyId;
  final StoryExperiencePlanId experiencePlanId;
  final String experiencePlanProcessingVersion;
  final MediaReference mediaReference;
  final String contentType;
  final int byteLength;
  final Duration? duration;
  final DateTime createdAt;
  final String? providerLabel;
  final String? modelLabel;
  final String? generationId;
  final String promptDigest;
  final String processingVersion;
  final bool instrumental;

  bool get isAiGenerated => true;

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
        mediaReference,
        contentType,
        byteLength,
        duration,
        createdAt,
        providerLabel,
        modelLabel,
        generationId,
        promptDigest,
        processingVersion,
        instrumental,
      ];
}
