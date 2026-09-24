import 'dart:typed_data';

/// Playback phase for the Hero's original captured recording.
///
/// This port plays stored bytes. It does not transform, transcribe, or
/// replace the recording.
enum OriginalRecordingPlaybackPhase { idle, playing, paused, completed, failed }

final class OriginalRecordingPlaybackSnapshot {
  const OriginalRecordingPlaybackSnapshot({
    required this.phase,
    this.errorMessage,
  });

  final OriginalRecordingPlaybackPhase phase;
  final String? errorMessage;
}

/// Presentation playback of an original captured recording.
///
/// Infrastructure adapters may use just_audio. Callers pass the bytes already
/// loaded through [StoryMediaStoragePort] / owned-media use cases.
abstract interface class OriginalRecordingPlayer {
  Stream<OriginalRecordingPlaybackSnapshot> get snapshots;

  /// Prepares [bytes] for playback without altering them.
  Future<void> load(Uint8List bytes);

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> dispose();
}

/// Creates a player for one Hero Story surface.
abstract interface class OriginalRecordingPlayerFactory {
  OriginalRecordingPlayer create();
}
