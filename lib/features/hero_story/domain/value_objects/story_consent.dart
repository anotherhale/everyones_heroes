import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Minimal independent consent gates for Story capture and publication.
///
/// Stages are independent: recorded ≠ processing ≠ publication ≠ AI ≠ voice ≠
/// music generation.
///
/// Voice rendering consent ([voiceRenderingApprovedAt]) is intentionally
/// separate from AI transformation consent. Recording, transcription,
/// processing, publication, or generic AI consent must never imply permission
/// to generate an AI voice presentation (HS.12.6 / HS-ADR-076).
///
/// Music generation consent ([musicGenerationApprovedAt]) is likewise
/// independent (Experiment A laboratory).
final class StoryConsent extends ValueObject {
  const StoryConsent({
    this.recordedAt,
    this.processingApprovedAt,
    this.publicationApprovedAt,
    this.aiTransformationApprovedAt,
    this.voiceRenderingApprovedAt,
    this.musicGenerationApprovedAt,
  });

  static const StoryConsent none = StoryConsent();

  final DateTime? recordedAt;
  final DateTime? processingApprovedAt;
  final DateTime? publicationApprovedAt;
  final DateTime? aiTransformationApprovedAt;
  final DateTime? voiceRenderingApprovedAt;
  final DateTime? musicGenerationApprovedAt;

  bool get isRecorded => recordedAt != null;
  bool get isProcessingApproved => processingApprovedAt != null;
  bool get isPublicationApproved => publicationApprovedAt != null;
  bool get isAiTransformationApproved => aiTransformationApprovedAt != null;
  bool get isVoiceRenderingApproved => voiceRenderingApprovedAt != null;
  bool get isMusicGenerationApproved => musicGenerationApprovedAt != null;

  StoryConsent markRecorded(DateTime at) {
    return StoryConsent(
      recordedAt: at,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent grantProcessing(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: at,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent grantPublication(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: at,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent grantAiTransformation(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: at,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent grantVoiceRendering(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: at,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent grantMusicGeneration(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: at,
    );
  }

  StoryConsent revokeProcessing() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: null,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent revokePublication() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: null,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent revokeAiTransformation() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: null,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent revokeVoiceRendering() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: null,
      musicGenerationApprovedAt: musicGenerationApprovedAt,
    );
  }

  StoryConsent revokeMusicGeneration() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
      musicGenerationApprovedAt: null,
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
      ];
}
