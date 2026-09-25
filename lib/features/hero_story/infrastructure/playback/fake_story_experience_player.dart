import 'dart:async';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_player.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_timeline.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Deterministic Story Experience player for tests.
final class FakeStoryExperiencePlayer implements StoryExperiencePlayer {
  FakeStoryExperiencePlayer({
    this.failOnLoad = false,
    this.failOnPlay = false,
    this.recordingDuration = const Duration(seconds: 30),
    StoryExperienceTimelineBuilder? timelineBuilder,
  }) : _timelineBuilder =
            timelineBuilder ?? const StoryExperienceTimelineBuilder();

  bool failOnLoad;
  bool failOnPlay;
  Duration recordingDuration;

  final StoryExperienceTimelineBuilder _timelineBuilder;
  final List<String> calls = <String>[];
  Uint8List? loadedBytes;
  StoryExperiencePlan? loadedPlan;
  Uint8List? loadedMusicBytes;
  Map<StoryExperiencePresentationPurpose, double>? loadedMusicVolumes;
  bool regeneratedPlan = false;
  bool invokedAi = false;

  StoryExperienceTimeline? _timeline;
  StoryExperienceDemoStem? currentStem;
  StoryExperiencePresentationPurpose? currentPurpose;
  double? currentMusicVolume;

  final StreamController<StoryExperiencePlaybackSnapshot> _snapshots =
      StreamController<StoryExperiencePlaybackSnapshot>.broadcast(sync: true);

  @override
  Stream<StoryExperiencePlaybackSnapshot> get snapshots => _snapshots.stream;

  @override
  StoryExperienceTimeline? get timeline => _timeline;

  @override
  Future<void> load({
    required Uint8List originalRecordingBytes,
    required StoryExperiencePlan plan,
    int? transcriptLength,
    Uint8List? presentationVoiceBytes,
    Uint8List? generatedMusicBytes,
    Map<StoryExperiencePresentationPurpose, double>? musicVolumesByPurpose,
  }) async {
    calls.add('load');
    if (failOnLoad) {
      throw StateError('Experience player failed to load.');
    }
    if (originalRecordingBytes.isEmpty) {
      throw StateError('Original recording is empty.');
    }
    loadedBytes = Uint8List.fromList(
      presentationVoiceBytes != null && presentationVoiceBytes.isNotEmpty
          ? presentationVoiceBytes
          : originalRecordingBytes,
    );
    loadedMusicBytes = generatedMusicBytes == null || generatedMusicBytes.isEmpty
        ? null
        : Uint8List.fromList(generatedMusicBytes);
    loadedMusicVolumes = musicVolumesByPurpose;
    loadedPlan = plan;
    _timeline = _timelineBuilder.build(
      plan: plan,
      recordingDuration: recordingDuration,
      transcriptLength: transcriptLength,
    );
  }

  @override
  Future<void> play() async {
    calls.add('play');
    if (failOnPlay) {
      throw StateError('Experience playback failed.');
    }
    if (_timeline == null) {
      throw StateError('Story experience is not loaded.');
    }
    // Simulate applying the opening cue.
    final opening = _timeline!.cues.isNotEmpty ? _timeline!.cues.first : null;
    currentPurpose = opening?.purpose;
    currentStem = opening?.stem;
    _emit(
      StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.playing,
        purpose: currentPurpose,
        stem: currentStem,
      ),
    );
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _emit(
      StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.paused,
        purpose: currentPurpose,
        stem: currentStem,
      ),
    );
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    currentStem = null;
    currentPurpose = null;
    _emit(
      const StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.idle,
      ),
    );
  }

  /// Advances to the next timeline cue (tests).
  void advanceToCue(int index) {
    final timeline = _timeline;
    if (timeline == null || index < 0 || index >= timeline.cues.length) {
      throw StateError('Invalid cue index $index.');
    }
    final cue = timeline.cues[index];
    currentPurpose = cue.purpose;
    currentStem = cue.stem;
    calls.add('cue:${cue.purpose.name}:${cue.stem?.name ?? 'none'}');
    if (cue.hasSilence) {
      calls.add('silence:${cue.silence.inMilliseconds}');
      _emit(
        StoryExperiencePlaybackSnapshot(
          phase: StoryExperiencePlaybackPhase.silenced,
          purpose: cue.purpose,
        ),
      );
    }
    _emit(
      StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.playing,
        purpose: currentPurpose,
        stem: currentStem,
      ),
    );
  }

  void completePlayback() {
    calls.add('completed');
    _emit(
      StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.completed,
        purpose: currentPurpose,
      ),
    );
  }

  void failPlayback([String message = 'Music playback failed.']) {
    calls.add('failed');
    _emit(
      StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.failed,
        errorMessage: message,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _snapshots.close();
  }

  void _emit(StoryExperiencePlaybackSnapshot snapshot) {
    if (!_snapshots.isClosed) {
      _snapshots.add(snapshot);
    }
  }
}

final class FakeStoryExperiencePlayerFactory
    implements StoryExperiencePlayerFactory {
  FakeStoryExperiencePlayerFactory(this.player);

  final FakeStoryExperiencePlayer player;

  @override
  StoryExperiencePlayer create() => player;
}
