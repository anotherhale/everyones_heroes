import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/emotional_character.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/religious_tradition.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_outcome.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/content_suitability.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/provenance_step.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/spirituality_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_consent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_geography.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_snapshot_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorySnapshotMapper', () {
    test('round-trips a fully populated story without domain events', () {
      final createdAt = DateTime.utc(2024, 6, 1, 10);
      final updatedAt = DateTime.utc(2024, 6, 2, 11);
      final occurredAt = DateTime.utc(2024, 6, 1, 10, 5);
      const representationId = StoryRepresentationId('rep-1');
      const transcriptId = StoryRepresentationId('rep-2');

      final story = Story(
        id: const StoryId('story-1'),
        heroId: const HeroId('hero-1'),
        title: StoryTitle('Showing Up'),
        narrative: StoryNarrative('I learned to keep showing up.'),
        originalLanguage: LanguageCode('en'),
        lifecycleStatus: StoryLifecycleStatus.approved,
        visibility: StoryVisibility.community,
        classification: StoryClassification(
          subjects: const [StorySubject.military, StorySubject.leadership],
          challenges: const [StoryChallenge.fear, StoryChallenge.change],
          outcomes: const [StoryOutcome.personalTransformation],
          emotionalCharacters: const [EmotionalCharacter.hopeful],
          narrativeThemeIds: const [NarrativeThemeId('theme-courage')],
          audience: StoryAudience.adult,
          geography: StoryGeography(
            country: 'US',
            region: 'TX',
            city: 'Austin',
            culturalContext: 'Veteran community',
          ),
        ),
        contentSuitability: const ContentSuitability(
          profanity: SuitabilityLevel.mild,
          violence: SuitabilityLevel.none,
          sexualContent: SuitabilityLevel.none,
          substanceUse: SuitabilityLevel.moderate,
          disturbingContent: SuitabilityLevel.none,
        ),
        spirituality: SpiritualityClassification(
          category: SpiritualityCategory.religious,
          tradition: ReligiousTradition.christianity,
        ),
        provenance: StoryProvenance(
          originalSourceDescription: 'Hero original audio capture',
          steps: [
            ProvenanceStep(
              transformationType: StoryTransformationType.transcription,
              producedRepresentationId: transcriptId,
              sourceRepresentationId: representationId,
              occurredAt: occurredAt,
              isAiAssisted: true,
              note: 'Auto transcript',
            ),
          ],
        ),
        consent: StoryConsent(
          recordedAt: createdAt,
          processingApprovedAt: createdAt,
          publicationApprovedAt: updatedAt,
          aiTransformationApprovedAt: null,
        ),
        representations: [
          StoryRepresentation(
            id: representationId,
            language: LanguageCode('en'),
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('file:///tmp/audio.m4a'),
            duration: const Duration(milliseconds: 12500),
          ),
          StoryRepresentation(
            id: transcriptId,
            language: LanguageCode('en'),
            format: StoryRepresentationFormat.transcript,
            origin: RepresentationOrigin.derived,
            textContent: 'I learned to keep showing up.',
            sourceRepresentationId: representationId,
            isAiGenerated: true,
            isApproved: false,
          ),
        ],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final json = StorySnapshotMapper.toJson(story);
      final restored = StorySnapshotMapper.fromJson(json);

      expect(restored.id, story.id);
      expect(restored.heroId, story.heroId);
      expect(restored.title.value, 'Showing Up');
      expect(restored.narrative.value, 'I learned to keep showing up.');
      expect(restored.narrative.isProvisional, isFalse);
      expect(restored.originalLanguage.value, 'en');
      expect(restored.lifecycleStatus, StoryLifecycleStatus.approved);
      expect(restored.visibility, StoryVisibility.community);
      expect(restored.classification.subjects, contains(StorySubject.military));
      expect(
        restored.classification.challenges,
        contains(StoryChallenge.fear),
      );
      expect(
        restored.classification.narrativeThemeIds.first.value,
        'theme-courage',
      );
      expect(restored.classification.audience, StoryAudience.adult);
      expect(restored.classification.geography!.city, 'Austin');
      expect(restored.contentSuitability.profanity, SuitabilityLevel.mild);
      expect(
        restored.spirituality.category,
        SpiritualityCategory.religious,
      );
      expect(
        restored.spirituality.tradition,
        ReligiousTradition.christianity,
      );
      expect(
        restored.provenance.originalSourceDescription,
        'Hero original audio capture',
      );
      expect(restored.provenance.steps, hasLength(1));
      expect(
        restored.provenance.steps.first.transformationType,
        StoryTransformationType.transcription,
      );
      expect(restored.consent.recordedAt!.toUtc(), createdAt);
      expect(restored.consent.aiTransformationApprovedAt, isNull);
      expect(restored.representations, hasLength(2));
      expect(
        restored.representations.first.duration,
        const Duration(milliseconds: 12500),
      );
      expect(restored.representations.first.mediaReference!.uri, 'file:///tmp/audio.m4a');
      expect(restored.representations.last.isAiGenerated, isTrue);
      expect(restored.createdAt.toUtc(), createdAt);
      expect(restored.updatedAt.toUtc(), updatedAt);
      expect(restored.pullDomainEvents(), isEmpty);

      expect(
        (json['representations'] as List).first['durationMs'],
        12500,
      );
    });

    test('round-trips provisional capture narrative', () {
      final story = Story(
        id: const StoryId('story-2'),
        heroId: const HeroId('hero-2'),
        title: StoryTitle('Untitled Story'),
        narrative: StoryNarrative.provisional(),
        originalLanguage: LanguageCode('es'),
        createdAt: DateTime.utc(2025, 2, 1),
        updatedAt: DateTime.utc(2025, 2, 1),
      );

      final restored = StorySnapshotMapper.fromJson(
        StorySnapshotMapper.toJson(story),
      );

      expect(restored.narrative.isProvisional, isTrue);
      expect(restored.narrative.value, StoryNarrative.provisionalText);
      expect(restored.pullDomainEvents(), isEmpty);
    });
  });
}
