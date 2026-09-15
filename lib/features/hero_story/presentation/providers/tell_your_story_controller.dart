import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
// AudioSource is exported by just_audio.

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/complete_story_capture_response.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_service.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_state.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// Presentation step inside Tell Your Story (distinct from session phase).
enum TellYourStoryStep {
  prepare,
  record,
  review,
  consent,
  completed,
}

@immutable
final class TellYourStoryUiState {
  const TellYourStoryUiState({
    required this.step,
    required this.phase,
    this.permissionStatus = DevicePermissionStatus.notDetermined,
    this.elapsed = Duration.zero,
    this.errorMessage,
    this.isBusy = false,
    this.grantProcessing = false,
    this.grantAiTransformation = false,
    this.capturedStoryId,
    this.title = '',
    this.isPlayingReview = false,
  });

  final TellYourStoryStep step;
  final RecordingSessionPhase phase;
  final DevicePermissionStatus permissionStatus;
  final Duration elapsed;
  final String? errorMessage;
  final bool isBusy;
  final bool grantProcessing;
  final bool grantAiTransformation;
  final StoryId? capturedStoryId;
  final String title;
  final bool isPlayingReview;

  TellYourStoryUiState copyWith({
    TellYourStoryStep? step,
    RecordingSessionPhase? phase,
    DevicePermissionStatus? permissionStatus,
    Duration? elapsed,
    String? errorMessage,
    bool clearError = false,
    bool? isBusy,
    bool? grantProcessing,
    bool? grantAiTransformation,
    StoryId? capturedStoryId,
    String? title,
    bool? isPlayingReview,
  }) {
    return TellYourStoryUiState(
      step: step ?? this.step,
      phase: phase ?? this.phase,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      elapsed: elapsed ?? this.elapsed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isBusy: isBusy ?? this.isBusy,
      grantProcessing: grantProcessing ?? this.grantProcessing,
      grantAiTransformation:
          grantAiTransformation ?? this.grantAiTransformation,
      capturedStoryId: capturedStoryId ?? this.capturedStoryId,
      title: title ?? this.title,
      isPlayingReview: isPlayingReview ?? this.isPlayingReview,
    );
  }
}

final tellYourStoryControllerProvider =
    NotifierProvider.autoDispose<TellYourStoryController, TellYourStoryUiState>(
      TellYourStoryController.new,
    );

/// Riverpod presentation coordinator for HS.9 Tell Your Story.
///
/// Business rules remain in [RecordingSessionService] / capture use cases.
final class TellYourStoryController extends Notifier<TellYourStoryUiState> {
  RecordingSessionService? _sessionRef;
  RecordingSessionService get _session {
    final existing = _sessionRef;
    if (existing != null) {
      return existing;
    }
    final created = ref.read(recordingSessionServiceProvider);
    _sessionRef = created;
    return created;
  }

  Timer? _elapsedTimer;
  StreamSubscription<DeviceRecordingFailureKind>? _failureSub;
  AudioPlayer? _player;

  @override
  TellYourStoryUiState build() {
    // Keep this flow alive across async recording operations.
    ref.keepAlive();
    _sessionRef ??= ref.read(recordingSessionServiceProvider);

    ref.onDispose(() {
      _elapsedTimer?.cancel();
      _failureSub?.cancel();
      unawaited(_player?.dispose());
      _sessionRef = null;
    });

    return const TellYourStoryUiState(
      step: TellYourStoryStep.prepare,
      phase: RecordingSessionPhase.idle,
    );
  }

  void _setState(TellYourStoryUiState next) {
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  Future<void> startFlow() async {
    _setState(state.copyWith(isBusy: true, clearError: true));
    try {
      final hero = await ref.read(ensureActiveLocalHeroProvider.future);
      await _session.beginSession(
        heroId: hero.id,
        originalLanguage: LanguageCode('en'),
      );
      final permission = await _session.prepare();
      _setState(state.copyWith(
        phase: _session.phase,
        permissionStatus: permission,
        isBusy: false,
        step: TellYourStoryStep.prepare,
      ));
      _listenDeviceFailures();
    } catch (e) {
      _setState(state.copyWith(
        isBusy: false,
        phase: RecordingSessionPhase.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> requestPermissions() async {
    _setState(state.copyWith(isBusy: true, clearError: true));
    try {
      final status = await _session.requestPermissions();
      _setState(state.copyWith(
        isBusy: false,
        permissionStatus: status,
        phase: _session.phase,
        errorMessage: _session.lastError,
      ));
    } catch (e) {
      _setState(state.copyWith(
        isBusy: false,
        errorMessage: e.toString(),
        phase: _session.phase,
      ));
    }
  }

  void continueToRecord() {
    if (state.permissionStatus != DevicePermissionStatus.granted) {
      _setState(state.copyWith(
        errorMessage: 'Microphone permission is required to record.',
      ));
      return;
    }
    _setState(state.copyWith(
      step: TellYourStoryStep.record,
      clearError: true,
      phase: _session.phase,
    ));
  }

  Future<void> startRecording() async {
    _setState(state.copyWith(isBusy: true, clearError: true));
    try {
      await _session.startRecording();
      _startElapsedTicker();
      _setState(state.copyWith(
        isBusy: false,
        phase: _session.phase,
        elapsed: Duration.zero,
      ));
    } catch (e) {
      _setState(state.copyWith(
        isBusy: false,
        phase: _session.phase,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> pauseRecording() async {
    await _session.pauseRecording();
    _elapsedTimer?.cancel();
    _setState(state.copyWith(phase: _session.phase));
  }

  Future<void> resumeRecording() async {
    await _session.resumeRecording();
    _startElapsedTicker();
    _setState(state.copyWith(phase: _session.phase));
  }

  Future<void> stopRecording() async {
    _setState(state.copyWith(isBusy: true, clearError: true));
    try {
      await _session.stopRecording();
      _elapsedTimer?.cancel();
      // Intentional Stop is a successful workflow transition — never carry an
      // interruption/error banner into the review screen.
      _setState(state.copyWith(
        isBusy: false,
        phase: _session.phase,
        step: TellYourStoryStep.review,
        elapsed: _session.artifact?.duration ?? state.elapsed,
        clearError: true,
      ));
    } catch (e) {
      _setState(state.copyWith(
        isBusy: false,
        phase: _session.phase,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> playReview() async {
    final artifact = _session.artifact;
    if (artifact == null) {
      _setState(state.copyWith(
        errorMessage: 'Nothing to play. Retake the recording.',
      ));
      return;
    }
    try {
      _player ??= AudioPlayer();
      if (artifact.hasBytes) {
        // Web (and any in-memory) artifacts: play from bytes without dart:io paths.
        await _player!.setAudioSource(
          AudioSource.uri(
            Uri.dataFromBytes(
              artifact.bytes!,
              mimeType: artifact.contentType,
            ),
          ),
        );
      } else {
        await _player!.setFilePath(artifact.localFilePath);
      }
      await _player!.play();
      _setState(state.copyWith(isPlayingReview: true, clearError: true));
      _player!.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          _setState(state.copyWith(isPlayingReview: false));
        }
      });
    } catch (e) {
      _setState(state.copyWith(
        isPlayingReview: false,
        errorMessage:
            'Playback failed. The recording may be corrupt — please retake.',
      ));
    }
  }

  Future<void> stopReviewPlayback() async {
    await _player?.stop();
    _setState(state.copyWith(isPlayingReview: false));
  }

  void updateTitle(String title) {
    _setState(state.copyWith(title: title));
  }

  Future<void> retake() async {
    await stopReviewPlayback();
    await _session.retake();
    _setState(state.copyWith(
      step: TellYourStoryStep.record,
      phase: _session.phase,
      elapsed: Duration.zero,
      clearError: true,
      isPlayingReview: false,
    ));
  }

  Future<void> discard() async {
    await stopReviewPlayback();
    await _session.discard();
    _setState(state.copyWith(
      step: TellYourStoryStep.prepare,
      phase: _session.phase,
      clearError: true,
      isPlayingReview: false,
    ));
  }

  Future<void> acceptRecording() async {
    if (state.errorMessage != null &&
        state.errorMessage!.contains('Playback failed')) {
      _setState(state.copyWith(
        errorMessage: 'Cannot accept a recording that failed playback.',
      ));
      return;
    }

    _setState(state.copyWith(isBusy: true, clearError: true));
    final title = state.title.trim().isEmpty
        ? null
        : StoryTitle(state.title.trim());

    final result = await _session.accept(title: title);
    if (result is Failure<CompleteStoryCaptureResponse>) {
      _setState(state.copyWith(
        isBusy: false,
        phase: _session.phase,
        errorMessage:
            'Story could not be saved. ${result.error} You can retry Accept.',
      ));
      return;
    }

    final response = (result as Success<CompleteStoryCaptureResponse>).value;
    _setState(state.copyWith(
      isBusy: false,
      phase: _session.phase,
      step: TellYourStoryStep.consent,
      capturedStoryId: response.storyId,
    ));
  }

  void setGrantProcessing(bool value) {
    _setState(state.copyWith(grantProcessing: value));
  }

  void setGrantAiTransformation(bool value) {
    _setState(state.copyWith(grantAiTransformation: value));
  }

  Future<void> submitConsent() async {
    final storyId = state.capturedStoryId;
    if (storyId == null) {
      _setState(state.copyWith(errorMessage: 'No captured story to update.'));
      return;
    }

    _setState(state.copyWith(isBusy: true, clearError: true));
    final updateConsent = ref.read(updateStoryConsentUseCaseProvider);
    final result = await updateConsent.execute(
      UpdateStoryConsentRequest(
        storyId: storyId,
        grantProcessing: state.grantProcessing,
        grantAiTransformation: state.grantAiTransformation,
      ),
    );

    if (result is Failure) {
      _setState(state.copyWith(
        isBusy: false,
        errorMessage: (result as Failure).error,
      ));
      return;
    }

    _setState(state.copyWith(
      isBusy: false,
      step: TellYourStoryStep.completed,
    ));
  }

  Future<void> skipConsentForNow() async {
    _setState(state.copyWith(
      step: TellYourStoryStep.completed,
      clearError: true,
    ));
  }

  void _startElapsedTicker() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!ref.mounted) {
        _elapsedTimer?.cancel();
        return;
      }
      final elapsed = await _session.elapsed;
      if (!ref.mounted) {
        return;
      }
      _setState(state.copyWith(elapsed: elapsed, phase: _session.phase));
    });
  }

  void _listenDeviceFailures() {
    _failureSub?.cancel();
    _failureSub = _session.deviceFailures.listen((kind) {
      // A clean intentional Stop already finalized review (phase reviewing,
      // no session error). Do not re-label that success as an interruption
      // if a late device stop-state event arrives.
      if (kind == DeviceRecordingFailureKind.interrupted &&
          state.step == TellYourStoryStep.review &&
          _session.phase == RecordingSessionPhase.reviewing &&
          _session.lastError == null) {
        return;
      }
      _setState(state.copyWith(
        errorMessage: _messageForFailure(kind),
        phase: _session.phase,
      ));
    });
  }

  String _messageForFailure(DeviceRecordingFailureKind kind) {
    return switch (kind) {
      DeviceRecordingFailureKind.permissionDenied =>
        'Microphone permission was revoked. Recording cannot continue.',
      DeviceRecordingFailureKind.microphoneUnavailable =>
        'Microphone became unavailable. Please try again.',
      DeviceRecordingFailureKind.cameraUnavailable =>
        'Camera is unavailable for this recording mode.',
      DeviceRecordingFailureKind.storageInsufficient =>
        'Not enough storage to continue recording.',
      DeviceRecordingFailureKind.interrupted =>
        'Recording was interrupted. You can review what was saved or retake.',
      DeviceRecordingFailureKind.startFailed =>
        'Could not start recording. Please try again.',
      DeviceRecordingFailureKind.stopFailed =>
        'Could not stop recording cleanly. Please retake.',
      DeviceRecordingFailureKind.unknown =>
        'Recording failed unexpectedly. Please try again.',
    };
  }
}
