import 'dart:async';

import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';

/// [DeviceRecordingPort] for platforms where on-device recording is unavailable
/// (e.g. Flutter Web without a media recorder adapter).
///
/// Reports [DevicePermissionStatus.unavailable] and rejects record operations
/// without touching the filesystem or requesting browser microphone permission.
final class UnavailableDeviceRecordingAdapter implements DeviceRecordingPort {
  UnavailableDeviceRecordingAdapter();

  final StreamController<DeviceRecordingFailureKind> _failures =
      StreamController<DeviceRecordingFailureKind>.broadcast();

  @override
  Stream<DeviceRecordingFailureKind> get failures => _failures.stream;

  @override
  Future<DevicePermissionStatus> checkMicrophonePermission() async {
    return DevicePermissionStatus.unavailable;
  }

  @override
  Future<DevicePermissionStatus> requestMicrophonePermission() async {
    return DevicePermissionStatus.unavailable;
  }

  @override
  Future<void> prepare({RecordingMode mode = RecordingMode.audio}) async {}

  @override
  Future<void> start({RecordingMode mode = RecordingMode.audio}) async {
    throw const DeviceRecordingException(
      'Device recording is unavailable on this platform.',
      kind: DeviceRecordingFailureKind.microphoneUnavailable,
    );
  }

  @override
  Future<void> pause() async {
    throw const DeviceRecordingException(
      'Device recording is unavailable on this platform.',
      kind: DeviceRecordingFailureKind.microphoneUnavailable,
    );
  }

  @override
  Future<void> resume() async {
    throw const DeviceRecordingException(
      'Device recording is unavailable on this platform.',
      kind: DeviceRecordingFailureKind.microphoneUnavailable,
    );
  }

  @override
  Future<LocalRecordingArtifact> stop() async {
    throw const DeviceRecordingException(
      'Device recording is unavailable on this platform.',
      kind: DeviceRecordingFailureKind.microphoneUnavailable,
    );
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<bool> get isRecording async => false;

  @override
  Future<bool> get isPaused async => false;

  @override
  Future<Duration> get elapsed async => Duration.zero;

  Future<void> dispose() async {
    await _failures.close();
  }
}
