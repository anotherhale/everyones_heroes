import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_player.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_timeline.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/just_audio_original_recording_player.dart';

/// just_audio experience player: Player A = original recording, Player B = stem.
///
/// Renders a persisted [StoryExperiencePlan]. Does not call AI, regenerate
/// the plan, or rewrite the original recording bytes.
final class JustAudioStoryExperiencePlayer implements StoryExperiencePlayer {
  JustAudioStoryExperiencePlayer({
    AudioPlayer? voicePlayer,
    AudioPlayer? musicPlayer,
    StoryExperienceTimelineBuilder? timelineBuilder,
    this.assetLoader,
  })  : _voiceOverride = voicePlayer,
        _musicOverride = musicPlayer,
        _timelineBuilder =
            timelineBuilder ?? const StoryExperienceTimelineBuilder();

  final AudioPlayer? _voiceOverride;
  final AudioPlayer? _musicOverride;
  AudioPlayer? _voiceLazy;
  AudioPlayer? _musicLazy;
  final StoryExperienceTimelineBuilder _timelineBuilder;

  AudioPlayer get _voice =>
      _voiceOverride ?? (_voiceLazy ??= AudioPlayer());
  AudioPlayer get _music =>
      _musicOverride ?? (_musicLazy ??= AudioPlayer());

  /// Optional override for loading stem bytes (tests). Defaults to asset source.
  final Future<ByteData> Function(String assetPath)? assetLoader;

  final StreamController<StoryExperiencePlaybackSnapshot> _snapshots =
      StreamController<StoryExperiencePlaybackSnapshot>.broadcast();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _voiceStateSub;
  Timer? _silenceTimer;

  StoryExperienceTimeline? _timeline;
  int _nextCueIndex = 0;
  bool _applyingCue = false;
  bool _userPaused = false;
  bool _disposed = false;
  StoryExperienceDemoStem? _currentStem;
  StoryExperiencePresentationPurpose? _currentPurpose;

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
  }) async {
    if (originalRecordingBytes.isEmpty) {
      throw StateError('Original recording is empty.');
    }

    final voiceBytes = presentationVoiceBytes == null ||
            presentationVoiceBytes.isEmpty
        ? originalRecordingBytes
        : presentationVoiceBytes;

    await _cancelSilence();
    await _positionSub?.cancel();
    await _voiceStateSub?.cancel();
    _nextCueIndex = 0;
    _currentStem = null;
    _currentPurpose = null;
    _userPaused = false;

    await _voice.setAudioSource(
      AudioSource.uri(
        Uri.dataFromBytes(
          voiceBytes,
          mimeType: mimeTypeForOriginalRecordingBytes(voiceBytes),
        ),
      ),
    );

    final duration = _voice.duration;
    if (duration == null || duration <= Duration.zero) {
      throw StateError('Unable to determine original recording duration.');
    }

    _timeline = _timelineBuilder.build(
      plan: plan,
      recordingDuration: duration,
      transcriptLength: transcriptLength,
    );

    _voiceStateSub = _voice.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        unawaited(_onVoiceCompleted());
      }
    });
  }

  @override
  Future<void> play() async {
    final timeline = _timeline;
    if (timeline == null) {
      throw StateError('Story experience is not loaded.');
    }
    _userPaused = false;
    await _cancelSilence();

    if (_voice.playerState.processingState == ProcessingState.completed ||
        _voice.position >= timeline.recordingDuration) {
      await _voice.seek(Duration.zero);
      _nextCueIndex = 0;
    }

    await _voice.play();
    _emit(
      StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.playing,
        purpose: _currentPurpose,
        stem: _currentStem,
      ),
    );

    await _positionSub?.cancel();
    _positionSub = _voice.positionStream.listen(_onPosition);
    // Apply opening cue immediately when starting from zero.
    if (_voice.position <= const Duration(milliseconds: 50) &&
        _nextCueIndex == 0 &&
        timeline.cues.isNotEmpty) {
      await _applyCue(timeline.cues[0]);
      _nextCueIndex = 1;
    }
  }

  @override
  Future<void> pause() async {
    _userPaused = true;
    await _cancelSilence();
    try {
      await _voice.pause();
    } catch (_) {}
    try {
      await _music.pause();
    } catch (_) {}
    _emit(
      StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.paused,
        purpose: _currentPurpose,
        stem: _currentStem,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _userPaused = false;
    await _cancelSilence();
    await _positionSub?.cancel();
    _positionSub = null;
    try {
      await _voice.stop();
      await _voice.seek(Duration.zero);
    } catch (_) {}
    try {
      await _music.stop();
    } catch (_) {}
    _nextCueIndex = 0;
    _currentStem = null;
    _currentPurpose = null;
    _emit(
      const StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.idle,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _cancelSilence();
    await _positionSub?.cancel();
    await _voiceStateSub?.cancel();
    if (_voiceOverride != null || _voiceLazy != null) {
      try {
        await _voice.dispose();
      } catch (_) {}
    }
    if (_musicOverride != null || _musicLazy != null) {
      try {
        await _music.dispose();
      } catch (_) {}
    }
    await _snapshots.close();
  }

  Future<void> _onPosition(Duration position) async {
    if (_userPaused || _applyingCue || _disposed) {
      return;
    }
    final timeline = _timeline;
    if (timeline == null) {
      return;
    }
    while (_nextCueIndex < timeline.cues.length) {
      final cue = timeline.cues[_nextCueIndex];
      if (position < cue.at) {
        break;
      }
      _nextCueIndex++;
      await _applyCue(cue);
      if (_userPaused || _disposed) {
        break;
      }
    }
  }

  Future<void> _applyCue(StoryExperienceTimelineCue cue) async {
    if (_disposed) {
      return;
    }
    _applyingCue = true;
    try {
      _currentPurpose = cue.purpose;

      if (cue.hasSilence) {
        await _music.stop();
        _currentStem = null;
        await _voice.pause();
        _emit(
          StoryExperiencePlaybackSnapshot(
            phase: StoryExperiencePlaybackPhase.silenced,
            purpose: cue.purpose,
          ),
        );
        final completed = Completer<void>();
        _silenceTimer = Timer(cue.silence, completed.complete);
        await completed.future;
        _silenceTimer = null;
        if (_disposed || _userPaused) {
          return;
        }
        await _voice.play();
      }

      if (cue.stem != null) {
        await _startStem(cue.stem!);
      } else if (cue.purpose == StoryExperiencePresentationPurpose.turningPoint) {
        await _music.stop();
        _currentStem = null;
      }

      if (!_userPaused && !_disposed) {
        _emit(
          StoryExperiencePlaybackSnapshot(
            phase: StoryExperiencePlaybackPhase.playing,
            purpose: _currentPurpose,
            stem: _currentStem,
          ),
        );
      }
    } finally {
      _applyingCue = false;
    }
  }

  Future<void> _startStem(StoryExperienceDemoStem stem) async {
    final path = StoryExperienceDemoStemAssets.assetPath(stem);
    try {
      // Prefer asset source; fall back to preloaded bytes when overridden.
      if (assetLoader != null) {
        final data = await assetLoader!(path);
        await _music.setAudioSource(
          AudioSource.uri(
            Uri.dataFromBytes(
              data.buffer.asUint8List(),
              mimeType: 'audio/wav',
            ),
          ),
        );
      } else {
        await _music.setAudioSource(AudioSource.asset(path));
      }
      await _music.setLoopMode(LoopMode.one);
      // Soft bed under the Hero's voice.
      await _music.setVolume(0.35);
      await _music.play();
      _currentStem = stem;
    } catch (_) {
      // Missing stem must not destroy the story — fall back to silence.
      try {
        await _music.stop();
      } catch (_) {}
      _currentStem = null;
    }
  }

  Future<void> _onVoiceCompleted() async {
    await _cancelSilence();
    await _music.stop();
    _currentStem = null;
    _emit(
      StoryExperiencePlaybackSnapshot(
        phase: StoryExperiencePlaybackPhase.completed,
        purpose: _currentPurpose,
      ),
    );
  }

  Future<void> _cancelSilence() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _emit(StoryExperiencePlaybackSnapshot snapshot) {
    if (!_snapshots.isClosed) {
      _snapshots.add(snapshot);
    }
  }
}

final class JustAudioStoryExperiencePlayerFactory
    implements StoryExperiencePlayerFactory {
  const JustAudioStoryExperiencePlayerFactory();

  @override
  StoryExperiencePlayer create() => JustAudioStoryExperiencePlayer();
}
