import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_consent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 9, 12);

  test('consent stages remain independent', () {
    var consent = StoryConsent.none.markRecorded(at);
    expect(consent.isRecorded, isTrue);
    expect(consent.isProcessingApproved, isFalse);
    expect(consent.isPublicationApproved, isFalse);
    expect(consent.isAiTransformationApproved, isFalse);
    expect(consent.isVoiceRenderingApproved, isFalse);

    consent = consent.grantProcessing(at);
    expect(consent.isProcessingApproved, isTrue);
    expect(consent.isPublicationApproved, isFalse);
    expect(consent.isAiTransformationApproved, isFalse);
    expect(consent.isVoiceRenderingApproved, isFalse);

    consent = consent.grantPublication(at);
    expect(consent.isPublicationApproved, isTrue);
    expect(consent.isAiTransformationApproved, isFalse);
    expect(consent.isVoiceRenderingApproved, isFalse);

    consent = consent.grantAiTransformation(at);
    expect(consent.isAiTransformationApproved, isTrue);
    expect(consent.isVoiceRenderingApproved, isFalse);

    consent = consent.grantVoiceRendering(at);
    expect(consent.isVoiceRenderingApproved, isTrue);
  });

  test('revoking one stage does not clear others', () {
    final consent = StoryConsent.none
        .markRecorded(at)
        .grantProcessing(at)
        .grantPublication(at)
        .grantAiTransformation(at)
        .grantVoiceRendering(at)
        .revokeProcessing()
        .revokePublication()
        .revokeAiTransformation();

    expect(consent.isRecorded, isTrue);
    expect(consent.isProcessingApproved, isFalse);
    expect(consent.isPublicationApproved, isFalse);
    expect(consent.isAiTransformationApproved, isFalse);
    expect(consent.isVoiceRenderingApproved, isTrue);
  });

  test('AI transformation consent does not imply voice rendering', () {
    final consent = StoryConsent.none
        .grantAiTransformation(at)
        .grantProcessing(at);
    expect(consent.isAiTransformationApproved, isTrue);
    expect(consent.isVoiceRenderingApproved, isFalse);
  });
}
