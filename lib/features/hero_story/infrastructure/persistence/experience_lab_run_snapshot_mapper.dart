import 'package:everyonesheroes/core/ids/experience_lab_run_id.dart';
import 'package:everyonesheroes/core/ids/experience_render_manifest_id.dart';
import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/experience_lab_experiment.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/experience_lab_run_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_provider_config.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_run.dart';

/// JSON snapshot mapper for durable [ExperienceLabRun] persistence.
abstract final class ExperienceLabRunSnapshotMapper {
  static Map<String, dynamic> toJson(ExperienceLabRun run) {
    return {
      'id': run.id.value,
      'storyId': run.storyId.value,
      'config': _configToJson(run.config),
      'experiencePlanId': run.experiencePlanId.value,
      'experiencePlanProcessingVersion': run.experiencePlanProcessingVersion,
      'voiceRenderingId': run.voiceRenderingId?.value,
      'musicRenderingId': run.musicRenderingId?.value,
      'renderManifestId': run.renderManifestId?.value,
      'status': run.status.name,
      'createdAt': run.createdAt.toIso8601String(),
      'completedAt': run.completedAt?.toIso8601String(),
      'errorSummary': run.errorSummary,
      'creativeDirectionDigest': run.creativeDirectionDigest,
      'processingVersion': run.processingVersion,
    };
  }

  static ExperienceLabRun fromJson(Map<String, dynamic> json) {
    final configRaw = json['config'];
    if (configRaw is! Map) {
      throw const FormatException(
        'ExperienceLabRun.config must be a JSON object.',
      );
    }

    return ExperienceLabRun(
      id: ExperienceLabRunId(json['id'] as String),
      storyId: StoryId(json['storyId'] as String),
      config: _configFromJson(Map<String, dynamic>.from(configRaw)),
      experiencePlanId: StoryExperiencePlanId(
        json['experiencePlanId'] as String,
      ),
      experiencePlanProcessingVersion:
          json['experiencePlanProcessingVersion'] as String,
      voiceRenderingId: _optionalId(
        json['voiceRenderingId'],
        StoryVoiceRenderingId.new,
      ),
      musicRenderingId: _optionalId(
        json['musicRenderingId'],
        MusicRenderingId.new,
      ),
      renderManifestId: _optionalId(
        json['renderManifestId'],
        ExperienceRenderManifestId.new,
      ),
      status: ExperienceLabRunStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      errorSummary: json['errorSummary'] as String?,
      creativeDirectionDigest: json['creativeDirectionDigest'] as String?,
      processingVersion: (json['processingVersion'] as String?) ??
          ExperienceLabRun.defaultProcessingVersion,
    );
  }

  static Map<String, dynamic> _configToJson(ExperienceLabProviderConfig config) {
    return {
      'experiment': config.experiment.name,
      'creativeProvider': config.creativeProvider,
      'creativeModel': config.creativeModel,
      'voiceProvider': config.voiceProvider,
      'voiceModel': config.voiceModel,
      'musicProvider': config.musicProvider,
      'musicModel': config.musicModel,
      'creativePromptVersion': config.creativePromptVersion,
      'voicePromptVersion': config.voicePromptVersion,
      'musicPromptVersion': config.musicPromptVersion,
    };
  }

  static ExperienceLabProviderConfig _configFromJson(
    Map<String, dynamic> json,
  ) {
    return ExperienceLabProviderConfig(
      experiment: ExperienceLabExperiment.values.byName(
        json['experiment'] as String,
      ),
      creativeProvider: json['creativeProvider'] as String,
      creativeModel: json['creativeModel'] as String,
      voiceProvider: json['voiceProvider'] as String,
      voiceModel: json['voiceModel'] as String,
      musicProvider: json['musicProvider'] as String,
      musicModel: json['musicModel'] as String,
      creativePromptVersion: (json['creativePromptVersion'] as String?) ??
          'exp-a.creative.v1',
      voicePromptVersion:
          (json['voicePromptVersion'] as String?) ?? 'hs12.6.v1',
      musicPromptVersion:
          (json['musicPromptVersion'] as String?) ?? 'exp-a.music.v1',
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
