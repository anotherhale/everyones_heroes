import 'dart:async';
import 'dart:io';

import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Deterministic in-process [DeviceRecordingPort] for tests and local flows.
final class FakeDeviceRecordingAdapter implements DeviceRecordingPort {
  FakeDeviceRecordingAdapter({
    Directory? outputDirectory,
    DevicePermissionStatus initialPermission =
        DevicePermissionStatus.granted,
    DateTime Function()? clock,
    String fakeBytes = 'fake-audio-bytes',
    String contentType = 'audio/m4a',
    this.autoGrantOnRequest = true,
  })  : _outputDirectory = outputDirectory ?? Directory.systemTemp,
        _permission = initialPermission,
        _clock = clock ?? DateTime.now,
        _fakeBytes = fakeBytes,
        _contentType = contentType;

  static const _uuid = Uuid();

  final Directory _outputDirectory;
  final DateTime Function() _clock;
  final String _fakeBytes;
  final String _contentType;

  /// When true, [requestMicrophonePermission] upgrades notDetermined/denied
  /// to granted (test convenience). Permanently denied / unavailable stay put.
  final bool autoGrantOnRequest;

  DevicePermissionStatus _permission;
  bool _prepared = false;
  bool _recording = false;
  bool _paused = false;
  String? _tempPath;
  RecordingMode _mode = RecordingMode.audio;
  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;
  DateTime? _segmentStartedAt;
  DeviceRecordingFailureKind? _nextFailure;
  final StreamController<DeviceRecordingFailureKind> _failures =
      StreamController<DeviceRecordingFailureKind>.broadcast();

  DevicePermissionStatus get permissionStatus => _permission;

  set permissionStatus(DevicePermissionStatus value) => _permission = value;

  /// Queue a failure for the next mutating call (start/pause/resume/stop).
  void simulateFailure(DeviceRecordingFailureKind kind) {
    _nextFailure = kind;
  }

  /// Emit an asynchronous interruption/failure on the failures stream.
  void emitFailure(DeviceRecordingFailureKind kind) {
    if (!_failures.isClosed) {
      _failures.add(kind);
    }
  }

  @override
  Stream<DeviceRecordingFailureKind> get failures => _failures.stream;

  @override
  Future<DevicePermissionStatus> checkMicrophonePermission() async {
    return _permission;
  }

  @override
  Future<DevicePermissionStatus> requestMicrophonePermission() async {
    if (_permission == DevicePermissionStatus.permanentlyDenied ||
        _permission == DevicePermissionStatus.unavailable) {
      return _permission;
    }
    if (autoGrantOnRequest &&
        (_permission == DevicePermissionStatus.notDetermined ||
            _permission == DevicePermissionStatus.denied)) {
      _permission = DevicePermissionStatus.granted;
    } else if (_permission == DevicePermissionStatus.notDetermined) {
      _permission = DevicePermissionStatus.denied;
    }
    return _permission;
  }

  @override
  Future<void> prepare({RecordingMode mode = RecordingMode.audio}) async {
    _throwIfQueued();
    if (mode == RecordingMode.video) {
      throw const DeviceRecordingException(
        'Fake adapter supports audio only in HS.9 MVP.',
        kind: DeviceRecordingFailureKind.cameraUnavailable,
      );
    }
    if (_permission == DevicePermissionStatus.unavailable) {
      throw const DeviceRecordingException(
        'Microphone unavailable.',
        kind: DeviceRecordingFailureKind.microphoneUnavailable,
      );
    }
    _mode = mode;
    _prepared = true;
  }

  @override
  Future<void> start({RecordingMode mode = RecordingMode.audio}) async {
    _throwIfQueued();
    if (!_prepared) {
      await prepare(mode: mode);
    }
    if (_permission != DevicePermissionStatus.granted) {
      final kind = DeviceRecordingFailureKind.permissionDenied;
      emitFailure(kind);
      throw DeviceRecordingException(
        'Microphone permission not granted.',
        kind: kind,
      );
    }
    if (_recording) {
      throw const DeviceRecordingException(
        'Already recording.',
        kind: DeviceRecordingFailureKind.startFailed,
      );
    }

    if (!await _outputDirectory.exists()) {
      await _outputDirectory.create(recursive: true);
    }

    final path = p.join(
      _outputDirectory.path,
      'fake-recording-${_uuid.v4()}.m4a',
    );
    _tempPath = path;
    _mode = mode;
    _recording = true;
    _paused = false;
    _startedAt = _clock();
    _segmentStartedAt = _startedAt;
    _accumulated = Duration.zero;
    await File(path).writeAsBytes(_fakeBytes.codeUnits, flush: true);
  }

  @override
  Future<void> pause() async {
    _throwIfQueued();
    if (!_recording || _paused) {
      throw const DeviceRecordingException(
        'Not recording or already paused.',
        kind: DeviceRecordingFailureKind.unknown,
      );
    }
    _flushSegment();
    _paused = true;
  }

  @override
  Future<void> resume() async {
    _throwIfQueued();
    if (!_recording || !_paused) {
      throw const DeviceRecordingException(
        'Not paused.',
        kind: DeviceRecordingFailureKind.unknown,
      );
    }
    _paused = false;
    _segmentStartedAt = _clock();
  }

  @override
  Future<LocalRecordingArtifact> stop() async {
    _throwIfQueued();
    if (!_recording) {
      throw const DeviceRecordingException(
        'Not recording.',
        kind: DeviceRecordingFailureKind.stopFailed,
      );
    }

    if (!_paused) {
      _flushSegment();
    }

    final path = _tempPath;
    if (path == null) {
      throw const DeviceRecordingException(
        'Missing temp recording path.',
        kind: DeviceRecordingFailureKind.stopFailed,
      );
    }

    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsBytes(_fakeBytes.codeUnits, flush: true);
    }

    final artifact = LocalRecordingArtifact(
      localFilePath: path,
      duration: _accumulated,
      contentType: _contentType,
      mode: _mode,
      byteLength: await file.length(),
      checksum: 'fake-${_fakeBytes.hashCode}',
    );

    _recording = false;
    _paused = false;
    _tempPath = null;
    _segmentStartedAt = null;
    return artifact;
  }

  @override
  Future<void> cancel() async {
    final path = _tempPath;
    _recording = false;
    _paused = false;
    _tempPath = null;
    _segmentStartedAt = null;
    _accumulated = Duration.zero;
    _startedAt = null;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  Future<bool> get isRecording async => _recording;

  @override
  Future<bool> get isPaused async => _paused;

  @override
  Future<Duration> get elapsed async {
    if (!_recording) {
      return _accumulated;
    }
    if (_paused || _segmentStartedAt == null) {
      return _accumulated;
    }
    return _accumulated + _clock().difference(_segmentStartedAt!);
  }

  Future<void> dispose() async {
    await cancel();
    await _failures.close();
  }

  void _flushSegment() {
    final started = _segmentStartedAt;
    if (started != null) {
      _accumulated += _clock().difference(started);
      _segmentStartedAt = null;
    }
  }

  void _throwIfQueued() {
    final kind = _nextFailure;
    if (kind == null) {
      return;
    }
    _nextFailure = null;
    emitFailure(kind);
    throw DeviceRecordingException('Simulated failure: $kind', kind: kind);
  }
}
