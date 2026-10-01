import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Minimal independent consent gates for Story capture and publication.
///
/// Stages are independent: recorded ≠ processing ≠ publication ≠ AI ≠ voice ≠
/// music generation ≠ voice cloning.
///
/// Voice rendering consent ([voiceRenderingApprovedAt]) is intentionally
/// separate from AI transformation consent. Recording, transcription,
/// processing, publication, or generic AI consent must never imply permission
/// to generate an AI voice presentation (HS.12.6 / HS-ADR-076).
///
/// Music generation consent ([musicGenerationApprovedAt]) is likewise
/// independent (Experiment A laboratory).
///
/// Voice cloning consent (HS.12.10 / HS-ADR-078):
/// - [voiceCloningAuthorizedAt] — explicit Story-level cloning grant
/// - [voiceCloningDeniedAt] — explicit Story-level denial (always wins over
///   profile-level cloning authorization under perProfile scope)
/// - Absence of both means "not granted" (not the same as explicit denial)
///
/// [voiceRenderingApprovedAt] must never imply cloning authorization.
final class StoryConsent extends ValueObject {
  const StoryConsent({
    this.recordedAt,
    this.processingApprovedAt,
    this.publicationApprovedAt,
    this.aiTransformationApprovedAt,
    this.voiceRenderingApprovedAt,
    this.musicGenerationApprovedAt,
    this.voiceCloningAuthorizedAt,
    this.voiceCloningDeniedAt,
  });

  static const StoryConsent none = StoryConsent();

  final DateTime? recordedAt;
  final DateTime? processingApprovedAt;
  final DateTime? publicationApprovedAt;
  final DateTime? aiTransformationApprovedAt;
  final DateTime? voiceRenderingApprovedAt;
  final DateTime? musicGenerationApprovedAt;

  /// Explicit Story-level voice cloning authorization timestamp.
  final DateTime? voiceCloningAuthorizedAt;

  /// Explicit Story-level voice cloning denial timestamp.
  ///
  /// When set, always blocks cloning regardless of VoiceProfile scope or
  /// profile-level cloning authorization (HS.12.10).
  final DateTime? voiceCloningDeniedAt;

  bool get isRecorded => recordedAt != null;
  bool get isProcessingApproved => processingApprovedAt != null;
  bool get isPublicationApproved => publicationApprovedAt != null;
  bool get isAiTransformationApproved => aiTransformationApprovedAt != null;
  bool get isVoiceRenderingApproved => voiceRenderingApprovedAt != null;
  bool get isMusicGenerationApproved => musicGenerationApprovedAt != null;

  /// True when Story-level cloning is explicitly authorized and not denied.
  bool get isVoiceCloningAuthorized =>
      voiceCloningAuthorizedAt != null && voiceCloningDeniedAt == null;

  /// True when Story-level cloning is explicitly denied.
  bool get isVoiceCloningDenied => voiceCloningDeniedAt != null;

  /// True when Story has neither granted nor explicitly denied cloning.
  bool get isVoiceCloningNotGranted =>
      voiceCloningAuthorizedAt == null && voiceCloningDeniedAt == null;

  StoryConsent markRecorded(DateTime at) {
    return _copy(recordedAt: at);
  }

  StoryConsent grantProcessing(DateTime at) {
    return _copy(processingApprovedAt: at);
  }

  StoryConsent grantPublication(DateTime at) {
    return _copy(publicationApprovedAt: at);
  }

  StoryConsent grantAiTransformation(DateTime at) {
    return _copy(aiTransformationApprovedAt: at);
  }

  StoryConsent grantVoiceRendering(DateTime at) {
    return _copy(voiceRenderingApprovedAt: at);
  }

  StoryConsent grantMusicGeneration(DateTime at) {
    return _copy(musicGenerationApprovedAt: at);
  }

  /// Grant Story-level voice cloning authorization.
  ///
  /// Clears any prior explicit denial. Does not imply voice rendering,
  /// enrollment, story-use, or publication authorization.
  StoryConsent grantVoiceCloning(DateTime at) {
    return _copy(
      voiceCloningAuthorizedAt: at,
      clearVoiceCloningDeniedAt: true,
    );
  }

  /// Explicitly deny Story-level voice cloning.
  ///
  /// Clears any prior authorization. Denial always wins over profile-level
  /// cloning authorization (HS.12.10).
  StoryConsent denyVoiceCloning(DateTime at) {
    return _copy(
      voiceCloningDeniedAt: at,
      clearVoiceCloningAuthorizedAt: true,
    );
  }

  StoryConsent revokeProcessing() {
    return _copy(clearProcessingApprovedAt: true);
  }

  StoryConsent revokePublication() {
    return _copy(clearPublicationApprovedAt: true);
  }

  StoryConsent revokeAiTransformation() {
    return _copy(clearAiTransformationApprovedAt: true);
  }

  StoryConsent revokeVoiceRendering() {
    return _copy(clearVoiceRenderingApprovedAt: true);
  }

  StoryConsent revokeMusicGeneration() {
    return _copy(clearMusicGenerationApprovedAt: true);
  }

  /// Clear Story-level cloning grant and denial back to "not granted".
  StoryConsent revokeVoiceCloning() {
    return _copy(
      clearVoiceCloningAuthorizedAt: true,
      clearVoiceCloningDeniedAt: true,
    );
  }

  StoryConsent _copy({
    DateTime? recordedAt,
    DateTime? processingApprovedAt,
    DateTime? publicationApprovedAt,
    DateTime? aiTransformationApprovedAt,
    DateTime? voiceRenderingApprovedAt,
    DateTime? musicGenerationApprovedAt,
    DateTime? voiceCloningAuthorizedAt,
    DateTime? voiceCloningDeniedAt,
    bool clearProcessingApprovedAt = false,
    bool clearPublicationApprovedAt = false,
    bool clearAiTransformationApprovedAt = false,
    bool clearVoiceRenderingApprovedAt = false,
    bool clearMusicGenerationApprovedAt = false,
    bool clearVoiceCloningAuthorizedAt = false,
    bool clearVoiceCloningDeniedAt = false,
  }) {
    return StoryConsent(
      recordedAt: recordedAt ?? this.recordedAt,
      processingApprovedAt: clearProcessingApprovedAt
          ? null
          : (processingApprovedAt ?? this.processingApprovedAt),
      publicationApprovedAt: clearPublicationApprovedAt
          ? null
          : (publicationApprovedAt ?? this.publicationApprovedAt),
      aiTransformationApprovedAt: clearAiTransformationApprovedAt
          ? null
          : (aiTransformationApprovedAt ?? this.aiTransformationApprovedAt),
      voiceRenderingApprovedAt: clearVoiceRenderingApprovedAt
          ? null
          : (voiceRenderingApprovedAt ?? this.voiceRenderingApprovedAt),
      musicGenerationApprovedAt: clearMusicGenerationApprovedAt
          ? null
          : (musicGenerationApprovedAt ?? this.musicGenerationApprovedAt),
      voiceCloningAuthorizedAt: clearVoiceCloningAuthorizedAt
          ? null
          : (voiceCloningAuthorizedAt ?? this.voiceCloningAuthorizedAt),
      voiceCloningDeniedAt: clearVoiceCloningDeniedAt
          ? null
          : (voiceCloningDeniedAt ?? this.voiceCloningDeniedAt),
    );
  }

  @override
  List<Object?> get equalityProps => [
        recordedAt,
        processingApprovedAt,
        publicationApprovedAt,
        aiTransformationApprovedAt,
        voiceRenderingApprovedAt,
        musicGenerationApprovedAt,
        voiceCloningAuthorizedAt,
        voiceCloningDeniedAt,
      ];
}
