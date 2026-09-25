import 'package:everyonesheroes/core/ids/experience_render_manifest_id.dart';
import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_music_prompt_builder.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_timeline.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_provider_config.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Builds an [ExperienceRenderManifest] from the existing timeline + lab assets.
///
/// Reuses [StoryExperienceTimelineBuilder] output. Strategy A maps each cue's
/// purpose onto a music volume for a single generated bed — no multi-clip
/// stitching.
final class ExperienceRenderManifestBuilder {
  const ExperienceRenderManifestBuilder();

  ExperienceRenderManifest build({
    required StoryExperiencePlan plan,
    required StoryExperienceTimeline timeline,
    required ExperienceLabProviderConfig config,
    MusicRenderingId? musicRenderingId,
    StoryVoiceRenderingId? voiceRenderingId,
    PresentationCreativeDirection? creativeDirection,
    ExperienceRenderRecordingRole recordingRole =
        ExperienceRenderRecordingRole.originalPlusNarrationBeds,
    DateTime? createdAt,
    ExperienceRenderManifestId? id,
  }) {
    final intensityByPurpose = <StoryExperiencePresentationPurpose,
        MusicIntensityLabel>{};
    if (creativeDirection != null) {
      for (final step in creativeDirection.intensityProgression) {
        intensityByPurpose[step.purpose] = step.intensity;
      }
    }

    final cues = timeline.cues.map((cue) {
      final label = intensityByPurpose[cue.purpose] ??
          ExperienceMusicPromptBuilder.intensityForPurpose(cue.purpose);
      final volume = label != null
          ? ExperienceMusicPromptBuilder.volumeForIntensity(label)
          : ExperienceMusicPromptBuilder.volumeForPurpose(cue.purpose);
      return ExperienceRenderMusicCue(
        at: cue.at,
        purpose: cue.purpose,
        musicVolume: volume,
        silence: cue.silence,
        intensityLabel: label?.name,
      );
    }).toList();

    return ExperienceRenderManifest(
      id: id ?? ExperienceRenderManifestId.generate(),
      storyId: plan.storyId,
      experiencePlanId: plan.id,
      experiencePlanProcessingVersion: plan.processingVersion,
      recordingRole: recordingRole,
      voiceRenderingId: voiceRenderingId,
      musicRenderingId: musicRenderingId,
      cues: cues,
      creativeDirectionDigest: creativeDirection == null
          ? null
          : '${creativeDirection.processingVersion}:'
              '${creativeDirection.musicPromptBrief.hashCode}',
      providerConfigFingerprint: config.fingerprint,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
