import 'package:everyonesheroes/core/ids/experience_render_manifest_id.dart';
import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';

/// How the voice track is sourced for a lab render.
enum ExperienceRenderRecordingRole {
  /// Hero's original recording (default identity signal).
  original,

  /// Persisted synthetic narration only.
  narrated,

  /// Original recording primary; narrated artifact available as alternate.
  originalPlusNarrationBeds,
}

/// Music intensity cue for Strategy A (single instrumental bed).
///
/// [musicVolume] is linear 0.0–1.0 for the existing just_audio player.
/// Stem vocabulary is preserved as metadata for the intensity curve only —
/// Experiment A does not stitch multi-clip stems.
final class ExperienceRenderMusicCue extends ValueObject {
  ExperienceRenderMusicCue({
    required this.at,
    required this.purpose,
    required this.musicVolume,
    this.silence = Duration.zero,
    this.intensityLabel,
  }) {
    if (musicVolume < 0.0 || musicVolume > 1.0) {
      throw ArgumentError('musicVolume must be between 0.0 and 1.0.');
    }
  }

  final Duration at;
  final StoryExperiencePresentationPurpose purpose;
  final double musicVolume;
  final Duration silence;

  /// Opaque intensity label (quiet/tension/build/expansive/resolve) when known.
  final String? intensityLabel;

  bool get hasSilence => silence > Duration.zero;

  @override
  List<Object?> get equalityProps =>
      [at, purpose, musicVolume, silence, intensityLabel];
}

/// Application render artifact — *how* a lab run is physically played.
///
/// Not canonical Story state. Not a domain twin of [StoryExperiencePlan].
/// Playback must reconstruct from this manifest without calling AI again.
final class ExperienceRenderManifest extends ValueObject {
  ExperienceRenderManifest({
    required this.id,
    required this.storyId,
    required this.experiencePlanId,
    required String experiencePlanProcessingVersion,
    required this.recordingRole,
    required this.cues,
    required this.createdAt,
    this.voiceRenderingId,
    this.musicRenderingId,
    String? creativeDirectionDigest,
    String? providerConfigFingerprint,
    String builderVersion = defaultBuilderVersion,
  })  : experiencePlanProcessingVersion =
            experiencePlanProcessingVersion.trim(),
        creativeDirectionDigest = _trimOrNull(creativeDirectionDigest),
        providerConfigFingerprint = _trimOrNull(providerConfigFingerprint),
        builderVersion = builderVersion.trim() {
    if (this.experiencePlanProcessingVersion.isEmpty) {
      throw ArgumentError('experiencePlanProcessingVersion cannot be blank.');
    }
    if (this.builderVersion.isEmpty) {
      throw ArgumentError('builderVersion cannot be blank.');
    }
  }

  static const String defaultBuilderVersion = 'exp-a.manifest.v1';

  final ExperienceRenderManifestId id;
  final StoryId storyId;
  final StoryExperiencePlanId experiencePlanId;
  final String experiencePlanProcessingVersion;
  final ExperienceRenderRecordingRole recordingRole;
  final StoryVoiceRenderingId? voiceRenderingId;
  final MusicRenderingId? musicRenderingId;
  final List<ExperienceRenderMusicCue> cues;
  final String? creativeDirectionDigest;
  final String? providerConfigFingerprint;
  final String builderVersion;
  final DateTime createdAt;

  /// True when required Strategy A artifacts are present for playback.
  bool get hasRequiredArtifacts => musicRenderingId != null;

  List<String> missingArtifactLabels() {
    final missing = <String>[];
    if (musicRenderingId == null) {
      missing.add('musicRendering');
    }
    if (recordingRole == ExperienceRenderRecordingRole.narrated &&
        voiceRenderingId == null) {
      missing.add('voiceRendering');
    }
    return missing;
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
        experiencePlanId,
        experiencePlanProcessingVersion,
        recordingRole,
        voiceRenderingId,
        musicRenderingId,
        cues,
        creativeDirectionDigest,
        providerConfigFingerprint,
        builderVersion,
        createdAt,
      ];
}
