import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'package:everyonesheroes/features/hero_story/application/playback/original_recording_player.dart';

/// Plays original recording bytes with just_audio.
///
/// The bytes are passed through as a data URI. The file on disk is not
/// rewritten and no derived audio representation is created.
final class JustAudioOriginalRecordingPlayer
    implements OriginalRecordingPlayer {
  JustAudioOriginalRecordingPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final StreamController<OriginalRecordingPlaybackSnapshot> _snapshots =
      StreamController<OriginalRecordingPlaybackSnapshot>.broadcast();
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  Stream<OriginalRecordingPlaybackSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> load(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw StateError('Original recording is empty.');
    }
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.dataFromBytes(
          bytes,
          mimeType: mimeTypeForOriginalRecordingBytes(bytes),
        ),
      ),
    );
    await _playerStateSub?.cancel();
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState != ProcessingState.completed) {
        return;
      }
      _emit(
        const OriginalRecordingPlaybackSnapshot(
          phase: OriginalRecordingPlaybackPhase.completed,
        ),
      );
      unawaited(_player.seek(Duration.zero));
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    _playerStateSub = null;
    await _player.dispose();
    await _snapshots.close();
  }

  void _emit(OriginalRecordingPlaybackSnapshot snapshot) {
    if (!_snapshots.isClosed) {
      _snapshots.add(snapshot);
    }
  }
}

final class JustAudioOriginalRecordingPlayerFactory
    implements OriginalRecordingPlayerFactory {
  const JustAudioOriginalRecordingPlayerFactory();

  @override
  OriginalRecordingPlayer create() => JustAudioOriginalRecordingPlayer();
}

/// Chooses a MIME type so just_audio can decode the original bytes.
///
/// WAV recordings (web capture) are detected from the RIFF/WAVE header.
/// Device capture is AAC in an MPEG-4 container (`audio/mp4`).
String mimeTypeForOriginalRecordingBytes(Uint8List bytes) {
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x41 &&
      bytes[10] == 0x56 &&
      bytes[11] == 0x45) {
    return 'audio/wav';
  }
  return 'audio/mp4';
}
