import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_run.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

final class RunExperienceLabResponse {
  const RunExperienceLabResponse({
    required this.labRun,
    required this.manifest,
    required this.musicRendering,
    this.voiceRendering,
    this.idempotentReplay = false,
  });

  final ExperienceLabRun labRun;
  final ExperienceRenderManifest manifest;
  final MusicRendering musicRendering;
  final StoryVoiceRendering? voiceRendering;
  final bool idempotentReplay;
}
