import 'dart:async';
import 'dart:io';

import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Production [DeviceRecordingPort] backed by package `record` + permissions.
///
/// Caller injects a cache/temp [Directory]; this adapter never imports domain
/// Story types.
final class RecordPackageDeviceRecordingAdapter implements DeviceRecordingPort {
  RecordPackageDeviceRecordingAdapter({
    required Directory tempDirectory,
    AudioRecorder? recorder,
    DateTime Function()? clock,
  })  : _tempDirectory = tempDirectory,
        _recorder = recorder ?? AudioRecorder(),
        _clock = clock ?? DateTime.now,
        _ownsRecorder = recorder == null;

  static const _uuid = Uuid();
  static const _contentType = 'audio/mp4';

  final Directory _tempDirectory;
  final AudioRecorder _recorder;
  final DateTime Function() _clock;
  final bool _ownsRecorder;

  final StreamController<DeviceRecordingFailureKind> _failures =
      StreamController<DeviceRecordingFailureKind>.broadcast();

  StreamSubscription<RecordState>? _stateSub;
  String? _tempPath;
  RecordingMode _mode = RecordingMode.audio;
  bool _prepared = false;
  DateTime? _segmentStartedAt;
  Duration _accumulated = Duration.zero;
  bool _trackingPaused = false;

  /// When true, [RecordState.stop] is expected from intentional stop/cancel
  /// and must not be reported as [DeviceRecordingFailureKind.interrupted].
  bool _expectingIntentionalStop = false;

  @override
  Stream<DeviceRecordingFailureKind> get failures => _failures.stream;

  @override
  Future<DevicePermissionStatus> checkMicrophonePermission() async {
    final status = await ph.Permission.microphone.status;
    return _mapPermission(status);
  }

  @override
  Future<DevicePermissionStatus> requestMicrophonePermission() async {
    final status = await ph.Permission.microphone.request();
    return _mapPermission(status);
  }

  @override
  Future<void> prepare({RecordingMode mode = RecordingMode.audio}) async {
    if (mode == RecordingMode.video) {
      throw const DeviceRecordingException(
        'Video recording is not supported in HS.9 MVP.',
        kind: DeviceRecordingFailureKind.cameraUnavailable,
      );
    }
    _mode = mode;
    await _ensureStateSubscription();
    if (!await _tempDirectory.exists()) {
      await _tempDirectory.create(recursive: true);
    }
    _prepared = true;
  }

  @override
  Future<void> start({RecordingMode mode = RecordingMode.audio}) async {
    if (!_prepared || mode != _mode) {
      await prepare(mode: mode);
    }

    final permission = await checkMicrophonePermission();
    if (permission != DevicePermissionStatus.granted) {
      final requested = await requestMicrophonePermission();
      if (requested != DevicePermissionStatus.granted) {
        const kind = DeviceRecordingFailureKind.permissionDenied;
        _emit(kind);
        throw const DeviceRecordingException(
          'Microphone permission denied.',
          kind: kind,
        );
      }
    }

    try {
      final path = p.join(_tempDirectory.path, 'recording-${_uuid.v4()}.m4a');
      _tempPath = path;
      _accumulated = Duration.zero;
      _trackingPaused = false;
      _segmentStartedAt = _clock();

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
    } catch (e) {
      const kind = DeviceRecordingFailureKind.startFailed;
      _emit(kind);
      _tempPath = null;
      _segmentStartedAt = null;
      throw DeviceRecordingException(
        'Failed to start recording: $e',
        kind: kind,
      );
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _recorder.pause();
      _flushSegment();
      _trackingPaused = true;
    } catch (e) {
      throw DeviceRecordingException(
        'Failed to pause recording: $e',
        kind: DeviceRecordingFailureKind.unknown,
      );
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _recorder.resume();
      _trackingPaused = false;
      _segmentStartedAt = _clock();
    } catch (e) {
      throw DeviceRecordingException(
        'Failed to resume recording: $e',
        kind: DeviceRecordingFailureKind.unknown,
      );
    }
  }

  @override
  Future<LocalRecordingArtifact> stop() async {
    _expectingIntentionalStop = true;
    try {
      if (!_trackingPaused) {
        _flushSegment();
      }
      final path = await _recorder.stop();
      final resolved = (path ?? _tempPath)?.trim();
      if (resolved == null || resolved.isEmpty) {
        const kind = DeviceRecordingFailureKind.stopFailed;
        _emit(kind);
        throw const DeviceRecordingException(
          'Recorder returned no output path.',
          kind: kind,
        );
      }

      final file = File(resolved);
      final length = await file.exists() ? await file.length() : 0;
      final artifact = LocalRecordingArtifact(
        localFilePath: resolved,
        duration: _accumulated,
        contentType: _contentType,
        mode: _mode,
        byteLength: length,
      );

      _tempPath = null;
      _segmentStartedAt = null;
      _trackingPaused = false;
      return artifact;
    } on DeviceRecordingException {
      rethrow;
    } catch (e) {
      const kind = DeviceRecordingFailureKind.stopFailed;
      _emit(kind);
      throw DeviceRecordingException(
        'Failed to stop recording: $e',
        kind: kind,
      );
    } finally {
      _expectingIntentionalStop = false;
    }
  }

  @override
  Future<void> cancel() async {
    _expectingIntentionalStop = true;
    try {
      try {
        await _recorder.cancel();
      } catch (_) {}

      final path = _tempPath;
      _tempPath = null;
      _segmentStartedAt = null;
      _accumulated = Duration.zero;
      _trackingPaused = false;

      if (path != null) {
        final file = File(path);
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    } finally {
      _expectingIntentionalStop = false;
    }
  }

  @override
  Future<bool> get isRecording async => _recorder.isRecording();

  @override
  Future<bool> get isPaused async => _recorder.isPaused();

  @override
  Future<Duration> get elapsed async {
    if (_trackingPaused || _segmentStartedAt == null) {
      return _accumulated;
    }
    final recording = await _recorder.isRecording();
    if (!recording) {
      return _accumulated;
    }
    return _accumulated + _clock().difference(_segmentStartedAt!);
  }

  Future<void> dispose() async {
    await _stateSub?.cancel();
    _stateSub = null;
    if (!_failures.isClosed) {
      await _failures.close();
    }
    if (_ownsRecorder) {
      await _recorder.dispose();
    }
  }

  Future<void> _ensureStateSubscription() async {
    if (_stateSub != null) {
      return;
    }
    _stateSub = _recorder.onStateChanged().listen(
      (state) {
        // Unexpected stop while we still track a temp path ≈ interruption.
        // Intentional stop/cancel also yield RecordState.stop; suppress those.
        if (state == RecordState.stop &&
            _tempPath != null &&
            !_expectingIntentionalStop) {
          _emit(DeviceRecordingFailureKind.interrupted);
        }
      },
      onError: (_) {
        _emit(DeviceRecordingFailureKind.unknown);
      },
    );
  }

  void _flushSegment() {
    final started = _segmentStartedAt;
    if (started != null) {
      _accumulated += _clock().difference(started);
      _segmentStartedAt = null;
    }
  }

  void _emit(DeviceRecordingFailureKind kind) {
    if (!_failures.isClosed) {
      _failures.add(kind);
    }
  }

  DevicePermissionStatus _mapPermission(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
      case ph.PermissionStatus.limited:
      case ph.PermissionStatus.provisional:
        return DevicePermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return DevicePermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return DevicePermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return DevicePermissionStatus.unavailable;
    }
  }
}
