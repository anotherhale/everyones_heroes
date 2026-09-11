import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_hero_search_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');
  final spanish = LanguageCode('es');
  final resilienceThemeId = NarrativeThemeId('resilience');

  test('hero search filters by experience area and language', () async {
    final repo = InMemoryHeroRepository();
    final matching = Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Sam',
        experienceAreas: const ['Military'],
        languages: [english],
      ),
    );
    final other = Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Pat',
        experienceAreas: const ['Arts'],
        languages: [spanish],
      ),
    );
    await repo.save(matching);
    await repo.save(other);

    final ids = await InMemoryHeroSearchAdapter(repo).search(
      HeroSearchQuery(experienceArea: 'Military', language: english),
    );

    expect(ids, [matching.id]);
  });

  group('StorySearchPort catalog filters', () {
    late InMemoryStoryRepository stories;
    late InMemoryStorySearchAdapter search;
    late HeroId heroId;

    Future<void> publishStory({
      required StoryId id,
      required LanguageCode originalLanguage,
      StoryClassification? classification,
      ContentSuitability? contentSuitability,
      SpiritualityClassification? spirituality,
      List<StoryRepresentation> representations = const [],
    }) async {
      final story = Story.create(
        id: id,
        heroId: heroId,
        title: StoryTitle('Catalog Story'),
        narrative: StoryNarrative('A cataloged lived experience.'),
        originalLanguage: originalLanguage,
      );

      if (classification != null) {
        story.classify(classification);
      }
      if (contentSuitability != null) {
        story.updateContentSuitability(contentSuitability);
      }
      if (spirituality != null) {
        story.updateSpirituality(spirituality);
      }
      for (final representation in representations) {
        story.addRepresentation(representation);
      }

      story
        ..submit()
        ..markReadyForReview()
        ..approve()
        ..changeVisibility(StoryVisibility.community)
        ..publish();

      await stories.save(story);
    }

    setUp(() {
      stories = InMemoryStoryRepository();
      search = InMemoryStorySearchAdapter(stories);
      heroId = HeroId.generate();
    });

    test('excludes unpublished by default', () async {
      final draft = Story.create(
        id: StoryId.generate(),
        heroId: heroId,
        title: StoryTitle('Draft'),
        narrative: StoryNarrative('Still a draft story.'),
        originalLanguage: english,
      );
      await stories.save(draft);

      final publishedId = StoryId.generate();
      await publishStory(id: publishedId, originalLanguage: english);

      final ids = await search.search(const StorySearchQuery(text: 'story'));
      expect(ids, [publishedId]);
    });

    test(
      'canonical multidimensional query matches via qualifying representation',
      () async {
        final matchingId = StoryId.generate();
        final nonMatchingId = StoryId.generate();
        final originalId = StoryRepresentationId.generate();
        final englishId = StoryRepresentationId.generate();

        await publishStory(
          id: matchingId,
          originalLanguage: spanish,
          classification: StoryClassification(
            subjects: const [StorySubject.military],
            narrativeThemeIds: [resilienceThemeId],
          ),
          contentSuitability: const ContentSuitability(
            profanity: SuitabilityLevel.none,
            violence: SuitabilityLevel.mild,
          ),
          spirituality: SpiritualityClassification.nonSpiritual,
          representations: [
            StoryRepresentation(
              id: originalId,
              language: spanish,
              format: StoryRepresentationFormat.audio,
              origin: RepresentationOrigin.original,
              mediaReference: MediaReference('media://es-original'),
              duration: const Duration(minutes: 18),
            ),
            StoryRepresentation(
              id: englishId,
              language: english,
              format: StoryRepresentationFormat.audio,
              origin: RepresentationOrigin.translated,
              sourceRepresentationId: originalId,
              mediaReference: MediaReference('media://en'),
              duration: const Duration(minutes: 9),
            ),
            StoryRepresentation(
              id: StoryRepresentationId.generate(),
              language: english,
              format: StoryRepresentationFormat.shortForm,
              origin: RepresentationOrigin.derived,
              sourceRepresentationId: englishId,
              mediaReference: MediaReference('media://en-short'),
              duration: const Duration(minutes: 6),
            ),
          ],
        );

        await publishStory(
          id: nonMatchingId,
          originalLanguage: english,
          classification: StoryClassification(
            subjects: const [StorySubject.arts],
            narrativeThemeIds: [NarrativeThemeId('courage')],
          ),
          contentSuitability: const ContentSuitability(
            profanity: SuitabilityLevel.strong,
          ),
          spirituality: SpiritualityClassification(
            category: SpiritualityCategory.religious,
            tradition: ReligiousTradition.christianity,
          ),
          representations: [
            StoryRepresentation(
              id: StoryRepresentationId.generate(),
              language: english,
              format: StoryRepresentationFormat.audio,
              origin: RepresentationOrigin.original,
              mediaReference: MediaReference('media://other'),
              duration: const Duration(minutes: 20),
            ),
          ],
        );

        final ids = await search.search(
          StorySearchQuery(
            subjects: const [StorySubject.military],
            narrativeThemeIds: [resilienceThemeId],
            availableLanguage: english,
            maxProfanity: SuitabilityLevel.none,
            spiritualityCategory: SpiritualityCategory.nonSpiritual,
            maxDuration: const Duration(minutes: 10),
          ),
        );

        expect(ids, [matchingId]);
      },
    );

    test('originalLanguage and availableLanguage remain distinct', () async {
      final storyId = StoryId.generate();
      final originalId = StoryRepresentationId.generate();

      await publishStory(
        id: storyId,
        originalLanguage: spanish,
        representations: [
          StoryRepresentation(
            id: originalId,
            language: spanish,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://es'),
            duration: const Duration(minutes: 12),
          ),
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.written,
            origin: RepresentationOrigin.translated,
            sourceRepresentationId: originalId,
            textContent: 'English translation',
            duration: const Duration(minutes: 11),
          ),
        ],
      );

      expect(
        await search.search(StorySearchQuery(originalLanguage: spanish)),
        [storyId],
      );
      expect(
        await search.search(StorySearchQuery(availableLanguage: english)),
        [storyId],
      );
      expect(
        await search.search(StorySearchQuery(originalLanguage: english)),
        isEmpty,
      );
    });

    test('duration uses ANY representation; null duration does not match',
        () async {
      final underMaxId = StoryId.generate();
      final overMaxId = StoryId.generate();
      final nullDurationId = StoryId.generate();
      final rangeId = StoryId.generate();

      final underOriginal = StoryRepresentationId.generate();
      await publishStory(
        id: underMaxId,
        originalLanguage: english,
        representations: [
          StoryRepresentation(
            id: underOriginal,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://under-long'),
            duration: const Duration(minutes: 18),
          ),
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.shortForm,
            origin: RepresentationOrigin.derived,
            sourceRepresentationId: underOriginal,
            mediaReference: MediaReference('media://under-short'),
            duration: const Duration(minutes: 6),
          ),
        ],
      );

      await publishStory(
        id: overMaxId,
        originalLanguage: english,
        representations: [
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://over'),
            duration: const Duration(minutes: 20),
          ),
        ],
      );

      await publishStory(
        id: nullDurationId,
        originalLanguage: english,
        representations: [
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.written,
            origin: RepresentationOrigin.original,
            textContent: 'No duration on this representation.',
          ),
        ],
      );

      final rangeOriginal = StoryRepresentationId.generate();
      await publishStory(
        id: rangeId,
        originalLanguage: english,
        representations: [
          StoryRepresentation(
            id: rangeOriginal,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://range-long'),
            duration: const Duration(minutes: 30),
          ),
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.derived,
            sourceRepresentationId: rangeOriginal,
            mediaReference: MediaReference('media://range-mid'),
            duration: const Duration(minutes: 8),
          ),
        ],
      );

      expect(
        await search.search(
          const StorySearchQuery(maxDuration: Duration(minutes: 10)),
        ),
        [underMaxId, rangeId],
      );
      expect(
        await search.search(
          const StorySearchQuery(maxDuration: Duration(minutes: 6)),
        ),
        [underMaxId],
      );

      final minResults = await search.search(
        const StorySearchQuery(minDuration: Duration(minutes: 15)),
      );
      expect(minResults, containsAll([underMaxId, overMaxId, rangeId]));
      expect(minResults, isNot(contains(nullDurationId)));

      // Same representation must satisfy both bounds.
      expect(
        await search.search(
          const StorySearchQuery(
            minDuration: Duration(minutes: 7),
            maxDuration: Duration(minutes: 10),
          ),
        ),
        [rangeId],
      );
    });

    test('suitability max filters apply to all dimensions', () async {
      final okId = StoryId.generate();
      final tooViolentId = StoryId.generate();

      await publishStory(
        id: okId,
        originalLanguage: english,
        contentSuitability: const ContentSuitability(
          profanity: SuitabilityLevel.none,
          violence: SuitabilityLevel.mild,
          sexualContent: SuitabilityLevel.none,
          substanceUse: SuitabilityLevel.none,
          disturbingContent: SuitabilityLevel.mild,
        ),
      );
      await publishStory(
        id: tooViolentId,
        originalLanguage: english,
        contentSuitability: const ContentSuitability(
          violence: SuitabilityLevel.strong,
        ),
      );

      expect(
        await search.search(
          const StorySearchQuery(
            maxProfanity: SuitabilityLevel.none,
            maxViolence: SuitabilityLevel.mild,
            maxSexualContent: SuitabilityLevel.mild,
            maxSubstanceUse: SuitabilityLevel.mild,
            maxDisturbingContent: SuitabilityLevel.mild,
          ),
        ),
        [okId],
      );
    });

    test('spirituality category and tradition filters', () async {
      final nonSpiritualId = StoryId.generate();
      final religiousId = StoryId.generate();

      await publishStory(
        id: nonSpiritualId,
        originalLanguage: english,
        spirituality: SpiritualityClassification.nonSpiritual,
      );
      await publishStory(
        id: religiousId,
        originalLanguage: english,
        spirituality: SpiritualityClassification(
          category: SpiritualityCategory.religious,
          tradition: ReligiousTradition.islam,
        ),
      );

      expect(
        await search.search(
          const StorySearchQuery(
            spiritualityCategory: SpiritualityCategory.nonSpiritual,
          ),
        ),
        [nonSpiritualId],
      );
      expect(
        await search.search(
          const StorySearchQuery(
            spiritualityCategory: SpiritualityCategory.religious,
            religiousTradition: ReligiousTradition.islam,
          ),
        ),
        [religiousId],
      );
    });

    test('format and geography filters use any-match / contains semantics',
        () async {
      final storyId = StoryId.generate();
      final originalId = StoryRepresentationId.generate();

      await publishStory(
        id: storyId,
        originalLanguage: english,
        classification: StoryClassification(
          geography: StoryGeography(
            country: 'United States',
            culturalContext: 'Rural Midwest',
          ),
        ),
        representations: [
          StoryRepresentation(
            id: originalId,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: MediaReference('media://audio'),
            duration: const Duration(minutes: 5),
          ),
          StoryRepresentation(
            id: StoryRepresentationId.generate(),
            language: english,
            format: StoryRepresentationFormat.video,
            origin: RepresentationOrigin.derived,
            sourceRepresentationId: originalId,
            mediaReference: MediaReference('media://video'),
            duration: const Duration(minutes: 5),
          ),
        ],
      );

      expect(
        await search.search(
          const StorySearchQuery(
            formats: [StoryRepresentationFormat.video],
            geographyCountry: 'united',
            geographyCulturalContext: 'midwest',
          ),
        ),
        [storyId],
      );
      expect(
        await search.search(
          const StorySearchQuery(
            formats: [StoryRepresentationFormat.transcript],
          ),
        ),
        isEmpty,
      );
    });

    test('combined AND across dimensions and OR within a dimension', () async {
      final militaryId = StoryId.generate();
      final careerId = StoryId.generate();

      await publishStory(
        id: militaryId,
        originalLanguage: english,
        classification: StoryClassification(
          subjects: const [StorySubject.military],
          outcomes: const [StoryOutcome.helpingOthers],
          emotionalCharacters: const [EmotionalCharacter.hopeful],
          audience: StoryAudience.adult,
          narrativeThemeIds: [resilienceThemeId],
        ),
      );
      await publishStory(
        id: careerId,
        originalLanguage: english,
        classification: StoryClassification(
          subjects: const [StorySubject.career],
          outcomes: const [StoryOutcome.careerChange],
          emotionalCharacters: const [EmotionalCharacter.serious],
          audience: StoryAudience.adult,
        ),
      );

      expect(
        await search.search(
          StorySearchQuery(
            subjects: const [StorySubject.military, StorySubject.career],
            audience: StoryAudience.adult,
            narrativeThemeIds: [resilienceThemeId],
          ),
        ),
        [militaryId],
      );
    });

    test('search results are deterministic across repeated calls', () async {
      final firstId = StoryId.generate();
      final secondId = StoryId.generate();
      await publishStory(id: firstId, originalLanguage: english);
      await publishStory(id: secondId, originalLanguage: english);

      const query = StorySearchQuery();
      expect(await search.search(query), await search.search(query));
      expect(await search.search(query), [firstId, secondId]);
    });

    test('Resilience is matched as NarrativeThemeId, not StoryChallenge',
        () async {
      final storyId = StoryId.generate();
      await publishStory(
        id: storyId,
        originalLanguage: english,
        classification: StoryClassification(
          challenges: const [StoryChallenge.failure],
          narrativeThemeIds: [resilienceThemeId],
        ),
      );

      expect(
        StoryChallenge.values.map((value) => value.name),
        isNot(contains('resilience')),
      );
      expect(
        await search.search(
          StorySearchQuery(narrativeThemeIds: [resilienceThemeId]),
        ),
        [storyId],
      );
    });
  });
}
