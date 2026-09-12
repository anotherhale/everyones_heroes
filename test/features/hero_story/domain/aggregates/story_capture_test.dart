import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');
  final at = DateTime.utc(2026, 9, 12);

  test('createFromCapture uses provisional narrative and private visibility', () {
    final story = Story.createFromCapture(
      id: StoryId.generate(),
      heroId: HeroId.generate(),
      originalLanguage: english,
    );

    expect(story.hasProvisionalNarrative, isTrue);
    expect(story.visibility, StoryVisibility.private);
    expect(story.lifecycleStatus, StoryLifecycleStatus.draft);
    expect(story.consent.isRecorded, isFalse);
  });

  test('submit and publish require independent consents', () {
    final story = Story.create(
      id: StoryId.generate(),
      heroId: HeroId.generate(),
      title: StoryTitle('Authored'),
      narrative: StoryNarrative('Canonical narrative'),
      originalLanguage: english,
    );

    expect(story.submit, throwsStateError);

    story.updateConsent(story.consent.grantProcessing(at));
    story.submit();
    story.markReadyForReview();
    story.approve();
    story.changeVisibility(StoryVisibility.public);

    expect(story.publish, throwsStateError);

    story.updateConsent(story.consent.grantPublication(at));
    story.publish();
    expect(story.isPublished, isTrue);
  });

  test('provisional narrative blocks approve/publish', () {
    final story = Story.createFromCapture(
      id: StoryId.generate(),
      heroId: HeroId.generate(),
      originalLanguage: english,
    );
    story.updateConsent(
      story.consent.grantProcessing(at).grantPublication(at),
    );
    story.submit();
    story.markReadyForReview();
    expect(story.approve, throwsStateError);

    story.updateNarrative(
      narrative: StoryNarrative('Authored after capture'),
    );
    story.approve();
    story.changeVisibility(StoryVisibility.public);
    story.publish();
    expect(story.isPublished, isTrue);
  });

  test('original audio representation records recording provenance', () {
    final story = Story.createFromCapture(
      id: StoryId.generate(),
      heroId: HeroId.generate(),
      originalLanguage: english,
    );

    story.addRepresentation(
      StoryRepresentation(
        id: StoryRepresentationId.generate(),
        language: english,
        format: StoryRepresentationFormat.audio,
        origin: RepresentationOrigin.original,
        mediaReference: MediaReference('memory://audio-1'),
        duration: const Duration(seconds: 12),
      ),
      transformationType: StoryTransformationType.recording,
      at: at,
    );
    story.markCaptureRecorded(at: at);

    expect(story.consent.isRecorded, isTrue);
    expect(
      story.provenance.steps.single.transformationType,
      StoryTransformationType.recording,
    );
  });
}
