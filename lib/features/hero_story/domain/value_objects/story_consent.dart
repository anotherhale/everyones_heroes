import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Minimal independent consent gates for Story capture and publication.
///
/// Stages are independent: recorded ≠ processing ≠ publication ≠ AI ≠ voice.
///
/// Voice rendering consent ([voiceRenderingApprovedAt]) is intentionally
/// separate from AI transformation consent. Recording, transcription,
/// processing, publication, or generic AI consent must never imply permission
/// to generate an AI voice presentation (HS.12.6 / HS-ADR-076).
final class StoryConsent extends ValueObject {
  const StoryConsent({
    this.recordedAt,
    this.processingApprovedAt,
    this.publicationApprovedAt,
    this.aiTransformationApprovedAt,
    this.voiceRenderingApprovedAt,
  });

  static const StoryConsent none = StoryConsent();

  final DateTime? recordedAt;
  final DateTime? processingApprovedAt;
  final DateTime? publicationApprovedAt;
  final DateTime? aiTransformationApprovedAt;
  final DateTime? voiceRenderingApprovedAt;

  bool get isRecorded => recordedAt != null;
  bool get isProcessingApproved => processingApprovedAt != null;
  bool get isPublicationApproved => publicationApprovedAt != null;
  bool get isAiTransformationApproved => aiTransformationApprovedAt != null;
  bool get isVoiceRenderingApproved => voiceRenderingApprovedAt != null;

  StoryConsent markRecorded(DateTime at) {
    return StoryConsent(
      recordedAt: at,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
    );
  }

  StoryConsent grantProcessing(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: at,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
    );
  }

  StoryConsent grantPublication(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: at,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
    );
  }

  StoryConsent grantAiTransformation(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: at,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
    );
  }

  StoryConsent grantVoiceRendering(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: at,
    );
  }

  StoryConsent revokeProcessing() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: null,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
    );
  }

  StoryConsent revokePublication() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: null,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
    );
  }

  StoryConsent revokeAiTransformation() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: null,
      voiceRenderingApprovedAt: voiceRenderingApprovedAt,
    );
  }

  StoryConsent revokeVoiceRendering() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
      voiceRenderingApprovedAt: null,
    );
  }

  @override
  List<Object?> get equalityProps => [
        recordedAt,
        processingApprovedAt,
        publicationApprovedAt,
        aiTransformationApprovedAt,
        voiceRenderingApprovedAt,
      ];
}
