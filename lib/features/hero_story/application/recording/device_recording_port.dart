import 'dart:typed_data';

/// Device microphone/camera recording boundary (HS.9 / HS-ADR-061).
///
/// Application/infrastructure concern — free of domain Story types and Flutter
/// UI. Infrastructure adapters may import `record`, `permission_handler`, etc.
enum RecordingMode {
  /// MVP production path.
  audio,

  /// Reserved for a later video slice; adapters may reject until supported.
  video,
}

enum DevicePermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

enum DeviceRecordingFailureKind {
  permissionDenied,
  microphoneUnavailable,
  cameraUnavailable,
  storageInsufficient,
  interrupted,
  startFailed,
  stopFailed,
  unknown,
}

/// Local temp recording result before durable [StoryMediaStoragePort] persist.
///
/// [localFilePath] is a filesystem path on native platforms. On web it may be a
/// synthetic marker (e.g. `memory://…`) or a short-lived object URL used only
/// inside infrastructure — application code should prefer [bytes] when present.
///
/// [bytes] carries the recorded media without exposing browser Blob / object-URL
/// types across the port boundary (required for Flutter Web).
final class LocalRecordingArtifact {
  const LocalRecordingArtifact({
    required this.localFilePath,
    required this.duration,
    required this.contentType,
    required this.mode,
    this.checksum,
    this.byteLength,
    this.bytes,
  });

  final String localFilePath;
  final Duration duration;
  final String contentType;
  final RecordingMode mode;
  final String? checksum;
  final int? byteLength;

  /// In-memory media payload (web recordings; optional on native).
  final Uint8List? bytes;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
}

final class DeviceRecordingException implements Exception {
  const DeviceRecordingException(
    this.message, {
    this.kind = DeviceRecordingFailureKind.unknown,
  });

  final String message;
  final DeviceRecordingFailureKind kind;

  @override
  String toString() => 'DeviceRecordingException($kind): $message';
}

/// Replaceable on-device recorder port.
abstract interface class DeviceRecordingPort {
  Future<DevicePermissionStatus> checkMicrophonePermission();

  Future<DevicePermissionStatus> requestMicrophonePermission();

  Future<void> prepare({RecordingMode mode = RecordingMode.audio});

  Future<void> start({RecordingMode mode = RecordingMode.audio});

  Future<void> pause();

  Future<void> resume();

  Future<LocalRecordingArtifact> stop();

  /// Discard in-progress or temp recording without producing an artifact.
  Future<void> cancel();

  /// Interruptions and hard failures while recording.
  Stream<DeviceRecordingFailureKind> get failures;

  Future<bool> get isRecording;

  Future<bool> get isPaused;

  Future<Duration> get elapsed;
}
