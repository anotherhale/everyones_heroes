import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Minimal independent consent gates for Story capture and publication.
///
/// Stages are independent: recorded ≠ processing ≠ publication ≠ AI.
final class StoryConsent extends ValueObject {
  const StoryConsent({
    this.recordedAt,
    this.processingApprovedAt,
    this.publicationApprovedAt,
    this.aiTransformationApprovedAt,
  });

  static const StoryConsent none = StoryConsent();

  final DateTime? recordedAt;
  final DateTime? processingApprovedAt;
  final DateTime? publicationApprovedAt;
  final DateTime? aiTransformationApprovedAt;

  bool get isRecorded => recordedAt != null;
  bool get isProcessingApproved => processingApprovedAt != null;
  bool get isPublicationApproved => publicationApprovedAt != null;
  bool get isAiTransformationApproved => aiTransformationApprovedAt != null;

  StoryConsent markRecorded(DateTime at) {
    return StoryConsent(
      recordedAt: at,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
    );
  }

  StoryConsent grantProcessing(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: at,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
    );
  }

  StoryConsent grantPublication(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: at,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
    );
  }

  StoryConsent grantAiTransformation(DateTime at) {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: at,
    );
  }

  StoryConsent revokeProcessing() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: null,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
    );
  }

  StoryConsent revokePublication() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: null,
      aiTransformationApprovedAt: aiTransformationApprovedAt,
    );
  }

  StoryConsent revokeAiTransformation() {
    return StoryConsent(
      recordedAt: recordedAt,
      processingApprovedAt: processingApprovedAt,
      publicationApprovedAt: publicationApprovedAt,
      aiTransformationApprovedAt: null,
    );
  }

  @override
  List<Object?> get equalityProps => [
    recordedAt,
    processingApprovedAt,
    publicationApprovedAt,
    aiTransformationApprovedAt,
  ];
}
