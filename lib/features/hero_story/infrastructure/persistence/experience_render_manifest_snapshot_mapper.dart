import 'package:everyonesheroes/core/ids/experience_render_manifest_id.dart';
import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';

/// JSON snapshot mapper for durable [ExperienceRenderManifest] persistence.
abstract final class ExperienceRenderManifestSnapshotMapper {
  static Map<String, dynamic> toJson(ExperienceRenderManifest manifest) {
    return {
      'id': manifest.id.value,
      'storyId': manifest.storyId.value,
      'experiencePlanId': manifest.experiencePlanId.value,
      'experiencePlanProcessingVersion':
          manifest.experiencePlanProcessingVersion,
      'recordingRole': manifest.recordingRole.name,
      'voiceRenderingId': manifest.voiceRenderingId?.value,
      'musicRenderingId': manifest.musicRenderingId?.value,
      'cues': [
        for (final cue in manifest.cues) _cueToJson(cue),
      ],
      'creativeDirectionDigest': manifest.creativeDirectionDigest,
      'providerConfigFingerprint': manifest.providerConfigFingerprint,
      'builderVersion': manifest.builderVersion,
      'createdAt': manifest.createdAt.toIso8601String(),
    };
  }

  static ExperienceRenderManifest fromJson(Map<String, dynamic> json) {
    final cuesRaw = json['cues'];
    if (cuesRaw is! List) {
      throw const FormatException(
        'ExperienceRenderManifest.cues must be a JSON array.',
      );
    }

    return ExperienceRenderManifest(
      id: ExperienceRenderManifestId(json['id'] as String),
      storyId: StoryId(json['storyId'] as String),
      experiencePlanId: StoryExperiencePlanId(
        json['experiencePlanId'] as String,
      ),
      experiencePlanProcessingVersion:
          json['experiencePlanProcessingVersion'] as String,
      recordingRole: ExperienceRenderRecordingRole.values.byName(
        json['recordingRole'] as String,
      ),
      voiceRenderingId: _optionalId(
        json['voiceRenderingId'],
        StoryVoiceRenderingId.new,
      ),
      musicRenderingId: _optionalId(
        json['musicRenderingId'],
        MusicRenderingId.new,
      ),
      cues: [
        for (final entry in cuesRaw)
          _cueFromJson(Map<String, dynamic>.from(entry as Map)),
      ],
      creativeDirectionDigest: json['creativeDirectionDigest'] as String?,
      providerConfigFingerprint: json['providerConfigFingerprint'] as String?,
      builderVersion: (json['builderVersion'] as String?) ??
          ExperienceRenderManifest.defaultBuilderVersion,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static Map<String, dynamic> _cueToJson(ExperienceRenderMusicCue cue) {
    return {
      'atMs': cue.at.inMilliseconds,
      'purpose': cue.purpose.name,
      'musicVolume': cue.musicVolume,
      'silenceMs': cue.silence.inMilliseconds,
      'intensityLabel': cue.intensityLabel,
    };
  }

  static ExperienceRenderMusicCue _cueFromJson(Map<String, dynamic> json) {
    final atMs = json['atMs'];
    if (atMs is! int) {
      throw const FormatException(
        'ExperienceRenderMusicCue.atMs must be an int.',
      );
    }
    final silenceMs = json['silenceMs'];
    if (silenceMs != null && silenceMs is! int) {
      throw const FormatException(
        'ExperienceRenderMusicCue.silenceMs must be an int.',
      );
    }
    final volumeRaw = json['musicVolume'];
    final musicVolume = switch (volumeRaw) {
      final double d => d,
      final int i => i.toDouble(),
      _ => throw const FormatException(
          'ExperienceRenderMusicCue.musicVolume must be a number.',
        ),
    };

    return ExperienceRenderMusicCue(
      at: Duration(milliseconds: atMs),
      purpose: StoryExperiencePresentationPurpose.values.byName(
        json['purpose'] as String,
      ),
      musicVolume: musicVolume,
      silence: Duration(milliseconds: (silenceMs as int?) ?? 0),
      intensityLabel: json['intensityLabel'] as String?,
    );
  }

  static T? _optionalId<T>(Object? raw, T Function(String) construct) {
    if (raw == null) {
      return null;
    }
    final value = raw as String;
    if (value.trim().isEmpty) {
      return null;
    }
    return construct(value);
  }
}
