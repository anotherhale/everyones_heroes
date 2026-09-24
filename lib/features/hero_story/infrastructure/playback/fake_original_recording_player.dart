import 'dart:async';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/application/playback/original_recording_player.dart';

/// Deterministic original-recording player for tests.
final class FakeOriginalRecordingPlayer implements OriginalRecordingPlayer {
  FakeOriginalRecordingPlayer({this.failOnPlay = false});

  bool failOnPlay;

  final List<String> calls = <String>[];
  Uint8List? loadedBytes;

  final StreamController<OriginalRecordingPlaybackSnapshot> _snapshots =
      StreamController<OriginalRecordingPlaybackSnapshot>.broadcast();

  @override
  Stream<OriginalRecordingPlaybackSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> load(Uint8List bytes) async {
    calls.add('load');
    if (bytes.isEmpty) {
      throw StateError('Original recording is empty.');
    }
    loadedBytes = Uint8List.fromList(bytes);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    if (failOnPlay) {
      throw StateError('Original recording is unavailable.');
    }
    _emit(OriginalRecordingPlaybackPhase.playing);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _emit(OriginalRecordingPlaybackPhase.paused);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _emit(OriginalRecordingPlaybackPhase.idle);
  }

  /// Simulates the player reaching the end of the original recording.
  void completePlayback() {
    calls.add('completed');
    _emit(OriginalRecordingPlaybackPhase.completed);
  }

  @override
  Future<void> dispose() async {
    await _snapshots.close();
  }

  void _emit(OriginalRecordingPlaybackPhase phase) {
    if (_snapshots.isClosed) {
      return;
    }
    _snapshots.add(OriginalRecordingPlaybackSnapshot(phase: phase));
  }
}

final class FakeOriginalRecordingPlayerFactory
    implements OriginalRecordingPlayerFactory {
  FakeOriginalRecordingPlayerFactory(this.player);

  final FakeOriginalRecordingPlayer player;

  @override
  OriginalRecordingPlayer create() => player;
}
