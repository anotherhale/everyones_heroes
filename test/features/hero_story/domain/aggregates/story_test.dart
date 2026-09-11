import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  final english = LanguageCode('en');
  final spanish = LanguageCode('es');

  Story createStory({LanguageCode? language}) {
    return Story.create(
      id: StoryId.generate(),
      heroId: HeroId.generate(),
      title: StoryTitle('Starting Over After Loss'),
      narrative: StoryNarrative(
        'I rebuilt my life after losing everything I thought defined me.',
      ),
      originalLanguage: language ?? english,
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

  group('Story lifecycle', () {
    test('create starts as draft and raises StoryCreated', () {
      final story = createStory();
      expect(story.lifecycleStatus, StoryLifecycleStatus.draft);
      expectEventRaised<StoryCreated>(story.pullDomainEvents());
    });

    test('submit -> review -> approve -> publish', () {
      final story = createStory();
      story.pullDomainEvents();

      story.submit();
      expect(story.lifecycleStatus, StoryLifecycleStatus.processing);
      expectEventRaised<StorySubmitted>(story.pullDomainEvents());

      story.markReadyForReview();
      story.approve();
      expect(story.lifecycleStatus, StoryLifecycleStatus.approved);
      expectEventRaised<StoryApproved>(story.pullDomainEvents());

      story.changeVisibility(StoryVisibility.public);
      story.publish();
      expect(story.isPublished, isTrue);
      expectEventRaised<StoryPublished>(story.pullDomainEvents());
    });

    test('cannot publish with draft visibility', () {
      final story = createStory();
      story.submit();
      story.markReadyForReview();
      story.approve();

      expect(story.publish, throwsStateError);
    });

    test('invalid lifecycle transitions throw', () {
      final story = createStory();
      expect(story.approve, throwsStateError);
    });

    test('archive published story', () {
      final story = createStory();
      story
        ..submit()
        ..markReadyForReview()
        ..approve()
        ..changeVisibility(StoryVisibility.public)
        ..publish()
        ..pullDomainEvents();

      story.archive();
      expect(story.lifecycleStatus, StoryLifecycleStatus.archived);
      expectEventRaised<StoryArchived>(story.pullDomainEvents());
    });
  });

  group('Story representations and provenance', () {
    test('adds original representation and records provenance', () {
      final story = createStory();
      story.pullDomainEvents();
      final representationId = StoryRepresentationId.generate();

      story.addRepresentation(
        originalAudio(representationId),
        transformationType: StoryTransformationType.recording,
      );

      expect(story.representations, hasLength(1));
      expect(story.provenance.steps, hasLength(1));
      expect(
        story.provenance.originalSourceDescription,
        'Original spoken recording',
      );
      expectEventRaised<StoryRepresentationAdded>(story.pullDomainEvents());
    });

    test('translated representation preserves source lineage', () {
      final story = createStory();
      final originalId = StoryRepresentationId.generate();
      final translationId = StoryRepresentationId.generate();

      story.addRepresentation(
        originalAudio(originalId),
        transformationType: StoryTransformationType.recording,
      );

      story.addRepresentation(
        StoryRepresentation(
          id: translationId,
          language: spanish,
          format: StoryRepresentationFormat.written,
          origin: RepresentationOrigin.translated,
          textContent: 'Reconstruí mi vida...',
          sourceRepresentationId: originalId,
          isAiGenerated: true,
        ),
        transformationType: StoryTransformationType.translation,
      );

      expect(story.availableLanguages, containsAll([english, spanish]));
      expect(story.provenance.steps.last.isAiAssisted, isTrue);
      expect(
        story.provenance.steps.last.sourceRepresentationId,
        originalId,
      );
    });

    test('AI-generated representation is non-authoritative until approved', () {
      final story = createStory();
      final originalId = StoryRepresentationId.generate();
      final aiId = StoryRepresentationId.generate();

      story.addRepresentation(originalAudio(originalId));
      story.addRepresentation(
        StoryRepresentation(
          id: aiId,
          language: english,
          format: StoryRepresentationFormat.transcript,
          origin: RepresentationOrigin.derived,
          textContent: 'AI transcript draft',
          sourceRepresentationId: originalId,
          isAiGenerated: true,
        ),
        transformationType: StoryTransformationType.transcription,
      );

      expect(story.findRepresentation(aiId)!.isAuthoritative, isFalse);

      story.approveRepresentation(aiId);
      expect(story.findRepresentation(aiId)!.isAuthoritative, isTrue);
    });

    test('original representation must match story original language', () {
      final story = createStory(language: english);

      expect(
        () => story.addRepresentation(
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: spanish,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://es'),
          ),
        ),
        throwsStateError,
      );
    });
  });

  group('Story catalog classification', () {
    test('classify stores multidimensional catalog and theme ids', () {
      final story = createStory();
      story.pullDomainEvents();
      final themeId = NarrativeThemeId.generate();

      story.classify(
        StoryClassification(
          subjects: const [StorySubject.startingOver],
          challenges: const [StoryChallenge.loss],
          narrativeThemeIds: [themeId],
          outcomes: const [StoryOutcome.personalTransformation],
          emotionalCharacters: const [EmotionalCharacter.hopeful],
          audience: StoryAudience.adult,
          geography: StoryGeography(country: 'United States'),
        ),
      );

      expect(story.classification.subjects, [StorySubject.startingOver]);
      expect(story.classification.narrativeThemeIds, [themeId]);
      expectEventRaised<StoryClassified>(story.pullDomainEvents());
    });

    test('content suitability is independent from classification', () {
      final story = createStory();
      story.updateContentSuitability(
        const ContentSuitability(
          profanity: SuitabilityLevel.mild,
          violence: SuitabilityLevel.none,
        ),
      );

      expect(story.contentSuitability.profanity, SuitabilityLevel.mild);
      expect(story.classification.isEmpty, isTrue);
    });

    test('spirituality may include tradition only when religious', () {
      expect(
        () => SpiritualityClassification(
          category: SpiritualityCategory.spiritual,
          tradition: ReligiousTradition.christianity,
        ),
        throwsArgumentError,
      );

      final story = createStory();
      story.updateSpirituality(
        SpiritualityClassification(
          category: SpiritualityCategory.religious,
          tradition: ReligiousTradition.buddhism,
        ),
      );

      expect(
        story.spirituality.category,
        SpiritualityCategory.religious,
      );
    });

    test('suitability and spirituality updates raise no domain events', () {
      final story = createStory();
      story.pullDomainEvents();

      story.updateContentSuitability(
        const ContentSuitability(violence: SuitabilityLevel.mild),
      );
      story.updateSpirituality(SpiritualityClassification.nonSpiritual);

      expect(story.pullDomainEvents(), isEmpty);
    });

    test('StoryChallenge enum does not include resilience', () {
      expect(
        StoryChallenge.values.map((value) => value.name),
        isNot(contains('resilience')),
      );
    });
  });
}
