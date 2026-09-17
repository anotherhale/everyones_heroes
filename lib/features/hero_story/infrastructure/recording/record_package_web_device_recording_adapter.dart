import 'dart:async';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/web_object_url_io.dart'
    as object_url;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Web [DeviceRecordingPort] backed by package `record` / `record_web`.
///
/// Differences from [RecordPackageDeviceRecordingAdapter] (native):
/// - Permissions use [AudioRecorder.hasPermission] (browser getUserMedia),
///   not `permission_handler`.
/// - Encoder is [AudioEncoder.wav] (always supported by `record_web`).
/// - [stop] materializes **bytes** from the browser object URL so application
///   layers never depend on `dart:io` filesystem paths or Blob types.
///
/// Browser APIs stay behind this adapter + [object_url] helpers.
final class RecordPackageWebDeviceRecordingAdapter
    implements DeviceRecordingPort {
  RecordPackageWebDeviceRecordingAdapter({
    AudioRecorder? recorder,
    DateTime Function()? clock,
    Future<Uint8List> Function(String url)? readObjectUrlBytes,
    void Function(String url)? revokeObjectUrl,
  })  : _recorder = recorder,
        _clock = clock ?? DateTime.now,
        _ownsRecorder = recorder == null,
        _readObjectUrlBytes =
            readObjectUrlBytes ?? object_url.readBytesFromObjectUrl,
        _revokeObjectUrl = revokeObjectUrl ?? object_url.revokeObjectUrl;

  static const _uuid = Uuid();
  static const _contentType = 'audio/wav';
  static const _encoder = AudioEncoder.wav;

  /// Lazily created so composition/tests can construct this adapter without a
  /// platform plugin binding until a real mic operation runs.
  AudioRecorder? _recorder;
  final DateTime Function() _clock;
  final bool _ownsRecorder;
  final Future<Uint8List> Function(String url) _readObjectUrlBytes;
  final void Function(String url) _revokeObjectUrl;

  AudioRecorder get _audio {
    return _recorder ??= AudioRecorder();
  }

  final StreamController<DeviceRecordingFailureKind> _failures =
      StreamController<DeviceRecordingFailureKind>.broadcast();

  StreamSubscription<RecordState>? _stateSub;
  String? _activeObjectUrl;
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
    try {
      final granted = await _audio.hasPermission(request: false);
      return granted
          ? DevicePermissionStatus.granted
          : DevicePermissionStatus.notDetermined;
    } catch (_) {
      return DevicePermissionStatus.unavailable;
    }
  }

  @override
  Future<DevicePermissionStatus> requestMicrophonePermission() async {
    try {
      final granted = await _audio.hasPermission(request: true);
      return granted
          ? DevicePermissionStatus.granted
          : DevicePermissionStatus.denied;
    } catch (_) {
      return DevicePermissionStatus.denied;
    }
  }

  @override
  Future<void> prepare({RecordingMode mode = RecordingMode.audio}) async {
    if (mode == RecordingMode.video) {
      throw const DeviceRecordingException(
        'Video recording is not supported in HS.9 MVP.',
        kind: DeviceRecordingFailureKind.cameraUnavailable,
      );
    }

    final supported = await _audio.isEncoderSupported(_encoder);
    if (!supported) {
      throw const DeviceRecordingException(
        'WAV recording is not supported in this browser.',
        kind: DeviceRecordingFailureKind.microphoneUnavailable,
      );
    }

    _mode = mode;
    await _ensureStateSubscription();
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
      _revokeActiveObjectUrl();
      _accumulated = Duration.zero;
      _trackingPaused = false;
      _segmentStartedAt = _clock();

      // Path is required by the record API; on web it is ignored by MediaRecorder
      // and stop() returns a blob object URL instead.
      await _audio.start(
        const RecordConfig(encoder: _encoder),
        path: 'recording-${_uuid.v4()}.wav',
      );
    } catch (e) {
      const kind = DeviceRecordingFailureKind.startFailed;
      _emit(kind);
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
      await _audio.pause();
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
      await _audio.resume();
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
    // Mark intentional stop and clear the interruption sentinel BEFORE invoking
    // the platform recorder so late RecordState.stop events are not mislabeled.
    _expectingIntentionalStop = true;
    try {
      if (!_trackingPaused) {
        _flushSegment();
      } else {
        // Already flushed on pause; ensure the interruption sentinel is clear.
        _segmentStartedAt = null;
      }

      final stopped = await _audio.stop();
      final objectUrl = stopped?.trim();
      if (objectUrl == null || objectUrl.isEmpty) {
        const kind = DeviceRecordingFailureKind.stopFailed;
        _emit(kind);
        throw const DeviceRecordingException(
          'Recorder returned no output.',
          kind: kind,
        );
      }

      _activeObjectUrl = objectUrl;
      final bytes = await _readObjectUrlBytes(objectUrl);
      if (bytes.isEmpty) {
        const kind = DeviceRecordingFailureKind.stopFailed;
        _emit(kind);
        throw const DeviceRecordingException(
          'Recorder produced empty audio data.',
          kind: kind,
        );
      }

      // Keep a synthetic path marker for logs/manifests; bytes are authoritative.
      final marker = 'memory://recording-${_uuid.v4()}.wav';
      final artifact = LocalRecordingArtifact(
        localFilePath: marker,
        duration: _accumulated,
        contentType: _contentType,
        mode: _mode,
        byteLength: bytes.length,
        bytes: Uint8List.fromList(bytes),
      );

      _revokeActiveObjectUrl();
      _segmentStartedAt = null;
      _trackingPaused = false;
      return artifact;
    } on DeviceRecordingException {
      _revokeActiveObjectUrl();
      rethrow;
    } catch (e) {
      _revokeActiveObjectUrl();
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
      final recorder = _recorder;
      if (recorder != null) {
        try {
          await recorder.cancel();
        } catch (_) {}
      }
      _revokeActiveObjectUrl();
      _segmentStartedAt = null;
      _accumulated = Duration.zero;
      _trackingPaused = false;
    } finally {
      _expectingIntentionalStop = false;
    }
  }

  @override
  Future<bool> get isRecording async {
    final recorder = _recorder;
    if (recorder == null) {
      return false;
    }
    return recorder.isRecording();
  }

  @override
  Future<bool> get isPaused async {
    final recorder = _recorder;
    if (recorder == null) {
      return false;
    }
    return recorder.isPaused();
  }

  @override
  Future<Duration> get elapsed async {
    if (_trackingPaused || _segmentStartedAt == null) {
      return _accumulated;
    }
    final recorder = _recorder;
    if (recorder == null) {
      return _accumulated;
    }
    final recording = await recorder.isRecording();
    if (!recording) {
      return _accumulated;
    }
    return _accumulated + _clock().difference(_segmentStartedAt!);
  }

  Future<void> dispose() async {
    await cancel();
    await _stateSub?.cancel();
    _stateSub = null;
    if (!_failures.isClosed) {
      await _failures.close();
    }
    final recorder = _recorder;
    _recorder = null;
    if (_ownsRecorder && recorder != null) {
      await recorder.dispose();
    }
  }

  Future<void> _ensureStateSubscription() async {
    if (_stateSub != null) {
      return;
    }
    _stateSub = _audio.onStateChanged().listen(
      (state) {
        // Intentional stop/cancel also yield RecordState.stop; suppress those.
        if (state == RecordState.stop &&
            _segmentStartedAt != null &&
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

  void _revokeActiveObjectUrl() {
    final url = _activeObjectUrl;
    _activeObjectUrl = null;
    if (url == null || url.isEmpty) {
      return;
    }
    try {
      _revokeObjectUrl(url);
    } catch (_) {}
  }

  void _emit(DeviceRecordingFailureKind kind) {
    if (!_failures.isClosed) {
      _failures.add(kind);
    }
  }
}

/// Factory used by composition roots (keeps import site stable).
DeviceRecordingPort createRecordPackageWebDeviceRecordingAdapter() {
  return RecordPackageWebDeviceRecordingAdapter();
}
