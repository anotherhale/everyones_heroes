import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_timeline.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Playback phase for a Story Experience (original recording + demo stems).
enum StoryExperiencePlaybackPhase {
  idle,
  loading,
  playing,
  paused,
  silenced,
  completed,
  failed,
}

final class StoryExperiencePlaybackSnapshot {
  const StoryExperiencePlaybackSnapshot({
    required this.phase,
    this.purpose,
    this.stem,
    this.errorMessage,
  });

  final StoryExperiencePlaybackPhase phase;
  final StoryExperiencePresentationPurpose? purpose;
  final StoryExperienceDemoStem? stem;
  final String? errorMessage;
}

/// Application-facing port that renders a persisted [StoryExperiencePlan].
///
/// Responsibilities:
/// - play the Hero's original recording bytes unchanged (default voice track)
/// - optionally play a previously persisted derived voice presentation
///   without regenerating it
/// - interpret the plan into a presentation timeline
/// - layer demo stems according to presentation purposes
/// - insert intentional silence as a playback gap (never rewrite media)
///
/// Must not call AI, regenerate the plan, mutate Story / transcript / reading.
abstract interface class StoryExperiencePlayer {
  Stream<StoryExperiencePlaybackSnapshot> get snapshots;

  /// Loads recording bytes and prepares playback for [plan].
  ///
  /// [originalRecordingBytes] remain the canonical fallback.
  /// When [presentationVoiceBytes] is provided (a previously persisted
  /// derived voice artifact), that audio is used as the voice track without
  /// invoking AI or regenerating audio.
  ///
  /// When [generatedMusicBytes] is provided (a previously persisted
  /// MusicRendering), Strategy A plays that single instrumental bed and
  /// modulates volume from timeline purposes instead of swapping demo stems.
  /// Demo-stem path is unchanged when music bytes are absent.
  ///
  /// [transcriptLength] improves proportional span→time mapping when known.
  /// Optional [musicVolumesByPurpose] overrides default intensity volumes
  /// when playing a generated bed (values from ExperienceRenderManifest).
  Future<void> load({
    required Uint8List originalRecordingBytes,
    required StoryExperiencePlan plan,
    int? transcriptLength,
    Uint8List? presentationVoiceBytes,
    Uint8List? generatedMusicBytes,
    Map<StoryExperiencePresentationPurpose, double>? musicVolumesByPurpose,
  });

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> dispose();

  /// Timeline built during [load], if any.
  StoryExperienceTimeline? get timeline;
}

abstract interface class StoryExperiencePlayerFactory {
  StoryExperiencePlayer create();
}
