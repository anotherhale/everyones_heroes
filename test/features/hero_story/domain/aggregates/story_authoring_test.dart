import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  final english = LanguageCode('en');

  Story createStory() {
    return Story.create(
      id: StoryId.generate(),
      heroId: HeroId.generate(),
      title: StoryTitle('Starting Over After Loss'),
      narrative: StoryNarrative(
        'I rebuilt my life after losing everything I thought defined me.',
      ),
      originalLanguage: english,
      originalSourceDescription: 'Original spoken recording',
    );
  }

  StoryRepresentation originalAudio(StoryRepresentationId id) {
    return StoryRepresentation(
      id: id,
      language: english,
      format: StoryRepresentationFormat.audio,
      origin: RepresentationOrigin.original,
      mediaReference: MediaReference('media://audio/original'),
      duration: const Duration(minutes: 8),
    );
  }

  test('approveRepresentation raises StoryRepresentationApproved once', () {
    final story = createStory();
    final audioId = StoryRepresentationId.generate();
    final transcriptId = StoryRepresentationId.generate();

    story.addRepresentation(
      originalAudio(audioId),
      transformationType: StoryTransformationType.recording,
    );
    story.pullDomainEvents();

    story.addRepresentation(
      StoryRepresentation(
        id: transcriptId,
        language: english,
        format: StoryRepresentationFormat.transcript,
        origin: RepresentationOrigin.derived,
        textContent: 'AI transcript draft',
        sourceRepresentationId: audioId,
        isAiGenerated: true,
      ),
      transformationType: StoryTransformationType.transcription,
    );
    story.pullDomainEvents();

    story.approveRepresentation(transcriptId);
    expectEventRaised<StoryRepresentationApproved>(story.pullDomainEvents());

    story.approveRepresentation(transcriptId);
    expect(story.pullDomainEvents(), isEmpty);
    expect(story.findRepresentation(transcriptId)!.isApproved, isTrue);
    expect(story.findRepresentation(transcriptId)!.isAuthoritative, isTrue);
  });

  test('replaceUnapprovedRepresentationText rejects approved representations',
      () {
    final story = createStory();
    final audioId = StoryRepresentationId.generate();
    final transcriptId = StoryRepresentationId.generate();

    story.addRepresentation(originalAudio(audioId));
    story.addRepresentation(
      StoryRepresentation(
        id: transcriptId,
        language: english,
        format: StoryRepresentationFormat.transcript,
        origin: RepresentationOrigin.derived,
        textContent: 'AI transcript draft',
        sourceRepresentationId: audioId,
        isAiGenerated: true,
      ),
      transformationType: StoryTransformationType.transcription,
    );
    story.approveRepresentation(transcriptId);

    expect(
      () => story.replaceUnapprovedRepresentationText(
        representationId: transcriptId,
        textContent: 'Nope',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
