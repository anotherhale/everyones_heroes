import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/complete_story_capture_response.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_manifest.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_state.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:path/path.dart' as p;

/// Orchestrates device recording → review → HS.3 capture completion (HS.9).
///
/// Session phase is an application concern, not Story lifecycle and not a
/// CaptureSession aggregate.
final class RecordingSessionService {
  RecordingSessionService({
    required DeviceRecordingPort recordingPort,
    required CompleteStoryCaptureUseCase completeCapture,
    Directory? manifestDirectory,
    String Function()? sessionIdFactory,
  })  : _recordingPort = recordingPort,
        _completeCapture = completeCapture,
        _manifestDirectory = manifestDirectory,
        _sessionIdFactory =
            sessionIdFactory ?? (() => StronglyTypedId.uuid.v4());

  final DeviceRecordingPort _recordingPort;
  final CompleteStoryCaptureUseCase _completeCapture;
  final Directory? _manifestDirectory;
  final String Function() _sessionIdFactory;

  RecordingSessionPhase _phase = RecordingSessionPhase.idle;
  String? _sessionId;
  HeroId? _heroId;
  StoryId? _storyId;
  StoryRepresentationId? _representationId;
  LanguageCode? _originalLanguage;
  RecordingMode _mode = RecordingMode.audio;
  LocalRecordingArtifact? _artifact;
  String? _lastError;
  DateTime? _createdAt;
  StoryTitle? _pendingTitle;
  String? _pendingSourceDescription;

  RecordingSessionPhase get phase => _phase;
  String? get sessionId => _sessionId;
  HeroId? get heroId => _heroId;
  StoryId? get storyId => _storyId;
  StoryRepresentationId? get representationId => _representationId;
  LanguageCode? get originalLanguage => _originalLanguage;
  RecordingMode get mode => _mode;
  LocalRecordingArtifact? get artifact => _artifact;
  String? get lastError => _lastError;

  Stream<DeviceRecordingFailureKind> get deviceFailures =>
      _recordingPort.failures;

  Future<Duration> get elapsed => _recordingPort.elapsed;

  /// Starts a new capture session identity (does not start the mic yet).
  Future<void> beginSession({
    required HeroId heroId,
    required LanguageCode originalLanguage,
    StoryId? storyId,
    StoryRepresentationId? representationId,
    RecordingMode mode = RecordingMode.audio,
    StoryTitle? title,
    String? originalSourceDescription,
  }) async {
    if (_phase == RecordingSessionPhase.recording ||
        _phase == RecordingSessionPhase.paused ||
        _phase == RecordingSessionPhase.persisting) {
      throw StateError(
        'Cannot begin a new session while phase is $_phase.',
      );
    }

    await _discardTempQuietly();

    _sessionId = _sessionIdFactory();
    _heroId = heroId;
    _storyId = storyId ?? StoryId.generate();
    _representationId = representationId ?? StoryRepresentationId.generate();
    _originalLanguage = originalLanguage;
    _mode = mode;
    _artifact = null;
    _lastError = null;
    _pendingTitle = title;
    _pendingSourceDescription = originalSourceDescription;
    _createdAt = DateTime.now().toUtc();
    _phase = RecordingSessionPhase.preparing;
    await _persistManifest();
  }

  Future<DevicePermissionStatus> prepare({
    RecordingMode mode = RecordingMode.audio,
  }) async {
    _ensureActiveSession();
    _mode = mode;
    _phase = RecordingSessionPhase.preparing;
    _lastError = null;
    await _persistManifest();

    try {
      await _recordingPort.prepare(mode: mode);
      final status = await _recordingPort.checkMicrophonePermission();
      if (status == DevicePermissionStatus.granted) {
        _phase = RecordingSessionPhase.ready;
      } else if (status == DevicePermissionStatus.unavailable) {
        _phase = RecordingSessionPhase.failed;
        _lastError = 'Microphone is unavailable on this device.';
      } else {
        // Stay preparing until permissions are requested/granted.
        _phase = RecordingSessionPhase.preparing;
      }
      await _persistManifest();
      return status;
    } on DeviceRecordingException catch (e) {
      _phase = RecordingSessionPhase.failed;
      _lastError = e.message;
      await _persistManifest();
      rethrow;
    }
  }

  Future<DevicePermissionStatus> requestPermissions() async {
    _ensureActiveSession();
    final status = await _recordingPort.requestMicrophonePermission();
    if (status == DevicePermissionStatus.granted) {
      _phase = RecordingSessionPhase.ready;
      _lastError = null;
    } else if (status == DevicePermissionStatus.permanentlyDenied ||
        status == DevicePermissionStatus.unavailable) {
      _phase = RecordingSessionPhase.failed;
      _lastError = 'Microphone permission was not granted.';
    } else {
      _phase = RecordingSessionPhase.preparing;
      _lastError = 'Microphone permission denied.';
    }
    await _persistManifest();
    return status;
  }

  /// Optional UI step before recording; does not change device state.
  Future<void> enterConsenting() async {
    _ensureActiveSession();
    if (_phase != RecordingSessionPhase.ready &&
        _phase != RecordingSessionPhase.consenting) {
      throw StateError('Can only enter consenting from ready (was $_phase).');
    }
    _phase = RecordingSessionPhase.consenting;
    await _persistManifest();
  }

  Future<void> startRecording() async {
    _ensureActiveSession();
    if (_phase != RecordingSessionPhase.ready &&
        _phase != RecordingSessionPhase.consenting) {
      throw StateError('Can only start recording from ready/consenting.');
    }

    try {
      await _recordingPort.start(mode: _mode);
      _phase = RecordingSessionPhase.recording;
      _lastError = null;
      await _persistManifest();
    } on DeviceRecordingException catch (e) {
      _phase = RecordingSessionPhase.failed;
      _lastError = e.message;
      await _persistManifest();
      rethrow;
    }
  }

  Future<void> pauseRecording() async {
    _ensureActiveSession();
    if (_phase != RecordingSessionPhase.recording) {
      throw StateError('Can only pause while recording.');
    }
    await _recordingPort.pause();
    _phase = RecordingSessionPhase.paused;
    await _persistManifest();
  }

  Future<void> resumeRecording() async {
    _ensureActiveSession();
    if (_phase != RecordingSessionPhase.paused) {
      throw StateError('Can only resume while paused.');
    }
    await _recordingPort.resume();
    _phase = RecordingSessionPhase.recording;
    await _persistManifest();
  }

  Future<LocalRecordingArtifact> stopRecording() async {
    _ensureActiveSession();
    if (_phase != RecordingSessionPhase.recording &&
        _phase != RecordingSessionPhase.paused) {
      throw StateError('Can only stop while recording or paused.');
    }

    try {
      final artifact = await _recordingPort.stop();
      _artifact = artifact;
      _phase = RecordingSessionPhase.reviewing;
      _lastError = null;
      await _persistManifest(tempPath: artifact.localFilePath);
      return artifact;
    } on DeviceRecordingException catch (e) {
      _phase = RecordingSessionPhase.failed;
      _lastError = e.message;
      await _persistManifest();
      rethrow;
    }
  }

  /// Discard current temp, mint a new sessionId, return to ready.
  Future<void> retake() async {
    _ensureActiveSession();
    if (_phase != RecordingSessionPhase.reviewing &&
        _phase != RecordingSessionPhase.recording &&
        _phase != RecordingSessionPhase.paused &&
        _phase != RecordingSessionPhase.failed) {
      throw StateError('Cannot retake from phase $_phase.');
    }

    await _recordingPort.cancel();
    await _deleteArtifactFile(_artifact?.localFilePath);
    _artifact = null;
    _sessionId = _sessionIdFactory();
    _representationId = StoryRepresentationId.generate();
    _lastError = null;
    _phase = RecordingSessionPhase.ready;
    await _persistManifest(clearTempPath: true);
  }

  /// Cancel temp media and clear the session back to idle/cancelled.
  Future<void> discard() async {
    if (_phase == RecordingSessionPhase.idle) {
      return;
    }

    try {
      await _recordingPort.cancel();
    } catch (_) {}
    await _deleteArtifactFile(_artifact?.localFilePath);
    _artifact = null;
    _lastError = null;
    _phase = RecordingSessionPhase.cancelled;
    await _persistManifest(clearTempPath: true);
    await _clearSessionIdentity();
  }

  /// Validate local artifact, complete HS.3 capture, delete temp on success.
  ///
  /// On storage/use-case failure: remain in [RecordingSessionPhase.reviewing]
  /// with temp retained for retry.
  Future<Result<CompleteStoryCaptureResponse>> accept({
    StoryTitle? title,
    String? originalSourceDescription,
    DateTime? occurredAt,
  }) async {
    _ensureActiveSession();
    if (_phase != RecordingSessionPhase.reviewing &&
        _phase != RecordingSessionPhase.failed) {
      return Failure('Can only accept a recording while reviewing.');
    }

    final artifact = _artifact;
    if (artifact == null) {
      return const Failure('No recording artifact available to accept.');
    }

    final file = File(artifact.localFilePath);
    if (!await file.exists()) {
      _lastError = 'Recording file is missing.';
      _phase = RecordingSessionPhase.failed;
      await _persistManifest();
      return Failure(_lastError!);
    }
    final length = await file.length();
    if (length == 0) {
      _lastError = 'Recording file is empty.';
      _phase = RecordingSessionPhase.failed;
      await _persistManifest();
      return Failure(_lastError!);
    }

    _phase = RecordingSessionPhase.persisting;
    await _persistManifest(tempPath: artifact.localFilePath);

    final result = await _completeCapture.execute(
      CompleteStoryCaptureRequest(
        sessionId: _sessionId!,
        heroId: _heroId!,
        storyId: _storyId!,
        representationId: _representationId!,
        originalLanguage: _originalLanguage!,
        mediaFilePath: artifact.localFilePath,
        contentType: artifact.contentType,
        checksum: artifact.checksum,
        duration: artifact.duration,
        title: title ?? _pendingTitle,
        originalSourceDescription:
            originalSourceDescription ?? _pendingSourceDescription,
        occurredAt: occurredAt,
      ),
    );

    if (result is Failure<CompleteStoryCaptureResponse>) {
      _lastError = result.error;
      // Stay reviewing so the caller can retry accept with the temp file.
      _phase = RecordingSessionPhase.reviewing;
      await _persistManifest(tempPath: artifact.localFilePath);
      return result;
    }

    await _deleteArtifactFile(artifact.localFilePath);
    _artifact = null;
    _lastError = null;
    _phase = RecordingSessionPhase.completed;
    await _persistManifest(clearTempPath: true);
    return result;
  }

  void _ensureActiveSession() {
    if (_sessionId == null ||
        _heroId == null ||
        _storyId == null ||
        _representationId == null ||
        _originalLanguage == null) {
      throw StateError('Recording session has not been begun.');
    }
  }

  Future<void> _discardTempQuietly() async {
    try {
      await _recordingPort.cancel();
    } catch (_) {}
    await _deleteArtifactFile(_artifact?.localFilePath);
    _artifact = null;
  }

  Future<void> _deleteArtifactFile(String? path) async {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }
    final file = File(trimmed);
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _clearSessionIdentity() async {
    await _deleteManifestFile();
    _sessionId = null;
    _heroId = null;
    _storyId = null;
    _representationId = null;
    _originalLanguage = null;
    _artifact = null;
    _pendingTitle = null;
    _pendingSourceDescription = null;
    _createdAt = null;
    _phase = RecordingSessionPhase.idle;
  }

  Future<void> _persistManifest({
    String? tempPath,
    bool clearTempPath = false,
  }) async {
    final directory = _manifestDirectory;
    final sessionId = _sessionId;
    if (directory == null || sessionId == null || _heroId == null) {
      return;
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final manifest = RecordingSessionManifest(
      sessionId: sessionId,
      heroId: _heroId!.value,
      storyId: _storyId!.value,
      representationId: _representationId!.value,
      phase: _phase,
      updatedAt: DateTime.now().toUtc(),
      tempPath: clearTempPath ? null : (tempPath ?? _artifact?.localFilePath),
      createdAt: _createdAt,
      originalLanguage: _originalLanguage?.value,
      contentType: _artifact?.contentType,
      lastError: _lastError,
    );

    final file = File(p.join(directory.path, '$sessionId.json'));
    await file.writeAsString(manifest.encode(), flush: true);
  }

  Future<void> _deleteManifestFile() async {
    final directory = _manifestDirectory;
    final sessionId = _sessionId;
    if (directory == null || sessionId == null) {
      return;
    }
    final file = File(p.join(directory.path, '$sessionId.json'));
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
