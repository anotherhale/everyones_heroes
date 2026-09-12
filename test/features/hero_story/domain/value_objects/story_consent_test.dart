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

    consent = consent.grantProcessing(at);
    expect(consent.isProcessingApproved, isTrue);
    expect(consent.isPublicationApproved, isFalse);
    expect(consent.isAiTransformationApproved, isFalse);

    consent = consent.grantPublication(at);
    expect(consent.isPublicationApproved, isTrue);
    expect(consent.isAiTransformationApproved, isFalse);

    consent = consent.grantAiTransformation(at);
    expect(consent.isAiTransformationApproved, isTrue);
  });

  test('revoking one stage does not clear others', () {
    final consent = StoryConsent.none
        .markRecorded(at)
        .grantProcessing(at)
        .grantPublication(at)
        .grantAiTransformation(at)
        .revokeProcessing()
        .revokePublication();

    expect(consent.isRecorded, isTrue);
    expect(consent.isProcessingApproved, isFalse);
    expect(consent.isPublicationApproved, isFalse);
    expect(consent.isAiTransformationApproved, isTrue);
  });
}
