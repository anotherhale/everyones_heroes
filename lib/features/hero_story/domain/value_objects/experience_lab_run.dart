import 'package:everyonesheroes/core/ids/experience_lab_run_id.dart';
import 'package:everyonesheroes/core/ids/experience_render_manifest_id.dart';
import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/experience_lab_run_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_provider_config.dart';

/// Laboratory experiment record for an AI-composed Hero Story experience.
///
/// Not canonical Story state. References derived presentation artifacts only.
/// Does not own Discovery / personalization / behavioral evidence.
final class ExperienceLabRun extends ValueObject {
  ExperienceLabRun({
    required this.id,
    required this.storyId,
    required this.config,
    required this.experiencePlanId,
    required String experiencePlanProcessingVersion,
    required this.status,
    required this.createdAt,
    this.voiceRenderingId,
    this.musicRenderingId,
    this.renderManifestId,
    this.completedAt,
    String? errorSummary,
    String? creativeDirectionDigest,
    String processingVersion = defaultProcessingVersion,
  })  : experiencePlanProcessingVersion =
            experiencePlanProcessingVersion.trim(),
        errorSummary = _trimOrNull(errorSummary),
        creativeDirectionDigest = _trimOrNull(creativeDirectionDigest),
        processingVersion = processingVersion.trim() {
    if (this.experiencePlanProcessingVersion.isEmpty) {
      throw ArgumentError('experiencePlanProcessingVersion cannot be blank.');
    }
    if (this.processingVersion.isEmpty) {
      throw ArgumentError('processingVersion cannot be blank.');
    }
  }

  static const String defaultProcessingVersion = 'exp-a.lab.v1';

  final ExperienceLabRunId id;
  final StoryId storyId;
  final ExperienceLabProviderConfig config;
  final StoryExperiencePlanId experiencePlanId;
  final String experiencePlanProcessingVersion;
  final StoryVoiceRenderingId? voiceRenderingId;
  final MusicRenderingId? musicRenderingId;
  final ExperienceRenderManifestId? renderManifestId;
  final ExperienceLabRunStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorSummary;
  final String? creativeDirectionDigest;
  final String processingVersion;

  bool get isPlayable =>
      status == ExperienceLabRunStatus.succeeded &&
      renderManifestId != null &&
      musicRenderingId != null;

  ExperienceLabRun copyWith({
    StoryVoiceRenderingId? voiceRenderingId,
    MusicRenderingId? musicRenderingId,
    ExperienceRenderManifestId? renderManifestId,
    ExperienceLabRunStatus? status,
    DateTime? completedAt,
    String? errorSummary,
    String? creativeDirectionDigest,
    bool clearError = false,
  }) {
    return ExperienceLabRun(
      id: id,
      storyId: storyId,
      config: config,
      experiencePlanId: experiencePlanId,
      experiencePlanProcessingVersion: experiencePlanProcessingVersion,
      voiceRenderingId: voiceRenderingId ?? this.voiceRenderingId,
      musicRenderingId: musicRenderingId ?? this.musicRenderingId,
      renderManifestId: renderManifestId ?? this.renderManifestId,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorSummary: clearError ? null : (errorSummary ?? this.errorSummary),
      creativeDirectionDigest:
          creativeDirectionDigest ?? this.creativeDirectionDigest,
      processingVersion: processingVersion,
    );
  }

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
        config,
        experiencePlanId,
        experiencePlanProcessingVersion,
        voiceRenderingId,
        musicRenderingId,
        renderManifestId,
        status,
        createdAt,
        completedAt,
        errorSummary,
        creativeDirectionDigest,
        processingVersion,
      ];
}
