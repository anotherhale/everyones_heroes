import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_consume_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_detail_screen.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/context/current_journey_context_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/repositories/reflection_repository_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/begin_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/begin_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/behavioral_evidence_detected.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/reflection_submitted.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:everyonesheroes/features/life_journey/presentation/providers/today_experience_provider.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/experience_screen.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/home_screen.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/reflect_screen.dart';

void main() {
  const storyIdValue = 'story-finding-forward';
  const storyTitle = 'Finding Forward';
  const narrative = 'I chose courage one ordinary morning.';
  const writtenText = 'The written form of finding forward.';
  const rationale =
      "This story connects with themes you've recently reflected on.";
  const candidateTitle = 'Finding Forward';

  final english = LanguageCode('en');

  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryReflectionRepository reflections;
  late JourneyId journeyId;
  late _CountingBeginExperienceUseCase beginExperience;
  late int todayBuilds;

  TodayExperienceViewModel storyCandidate({
    String id = 'adaptive-story-$storyIdValue',
    String? targetId = storyIdValue,
    String? why = rationale,
    String title = candidateTitle,
  }) {
    return TodayExperienceViewModel(
      id: id,
      experienceType: ExperienceType.story,
      action: ExperienceAction.begin,
      title: title,
      description:
          'A story that connects with themes you have been exploring '
          'on your journey.',
      callToAction: 'Begin Experience',
      rationale: why,
      storyTargetId: targetId,
    );
  }

  TodayExperienceViewModel reflectionCandidate() {
    return const TodayExperienceViewModel(
      id: 'default-reflection',
      experienceType: ExperienceType.reflection,
      action: ExperienceAction.begin,
      title: 'Keep Showing Up',
      description: 'Take one small step today.',
      callToAction: 'Begin Experience',
      rationale:
          'You have been building consistency across your recent journey.',
    );
  }

  Future<Story> seedStory({
    List<StoryRepresentation> representations = const [],
    String id = storyIdValue,
    String title = storyTitle,
    String body = narrative,
  }) async {
    final hero = hs.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Alex Rivera',
        biography: 'Service and starting over.',
        experienceAreas: const ['Service'],
        languages: [english],
      ),
      visibility: HeroVisibility.public,
    );
    await heroes.save(hero);

    final story = Story.create(
      id: StoryId(id),
      heroId: hero.id,
      title: StoryTitle(title),
      narrative: StoryNarrative(body),
      originalLanguage: english,
    );
    for (final representation in representations) {
      story.addRepresentation(representation);
    }
    story.updateConsent(
      story.consent
          .grantProcessing(DateTime.utc(2026, 1, 1))
          .grantPublication(DateTime.utc(2026, 1, 1)),
    );
    story
      ..submit()
      ..markReadyForReview()
      ..approve()
      ..changeVisibility(StoryVisibility.public)
      ..publish();
    await stories.save(story);
    return story;
  }

  StoryRepresentation writtenRep(String text) {
    return StoryRepresentation(
      id: StoryRepresentationId('written-en'),
      language: english,
      format: StoryRepresentationFormat.written,
      origin: RepresentationOrigin.original,
      textContent: text,
    );
  }

  StoryRepresentation audioWithoutBytes() {
    return StoryRepresentation(
      id: StoryRepresentationId('audio-en'),
      language: english,
      format: StoryRepresentationFormat.audio,
      origin: RepresentationOrigin.original,
      mediaReference: MediaReference('memory://missing-audio'),
      textContent: 'Spoken words that must not replace the narrative.',
    );
  }

  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    required TodayExperienceViewModel experience,
    CurrentJourneyContext? journey,
  }) async {
    todayBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        reflectionRepositoryProvider.overrideWithValue(reflections),
        beginExperienceUseCaseProvider.overrideWithValue(beginExperience),
        if (journey != null)
          currentJourneyContextProvider.overrideWithValue(journey),
        todayExperienceProvider.overrideWith((ref) async {
          todayBuilds++;
          return experience;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('today-experience-begin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('begin-experience-button')));
    await tester.pumpAndSettle();
  }

  setUp(() {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    reflections = InMemoryReflectionRepository();
    journeyId = JourneyId.generate();
    beginExperience = _CountingBeginExperienceUseCase(
      result: Success(
        Reflection.create(
          id: ReflectionId.generate(),
          journeyId: JourneyId.generate(),
        ),
      ),
    );
  });

  group('Today → Detail continuity', () {
    testWidgets(
      'adaptive-story candidate resolves to the expected local Story',
      (tester) async {
        await seedStory(representations: [writtenRep(writtenText)]);
        await pumpHome(tester, experience: storyCandidate());

        expect(find.text("TODAY'S EXPERIENCE"), findsOneWidget);
        expect(find.text(candidateTitle), findsOneWidget);
        expect(find.text('YOUR JOURNEY'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('today-why-this-story')),
          findsOneWidget,
        );
        expect(find.text('Why this Story?'), findsOneWidget);
        expect(find.text(rationale), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('today-experience-begin')));
        await tester.pumpAndSettle();

        expect(find.byType(ExperienceScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('experience-why-this-story')),
          findsOneWidget,
        );
        expect(beginExperience.executeCount, 0);

        await tester.tap(find.byKey(const ValueKey('begin-experience-button')));
        await tester.pumpAndSettle();

        expect(beginExperience.executeCount, 0);
        expect(find.byType(ReflectScreen), findsNothing);
        final detail = tester.widget<StoryDetailScreen>(
          find.byType(StoryDetailScreen),
        );
        expect(detail.storyId, storyIdValue);
        expect(
          find.byKey(const ValueKey('story-detail-title')),
          findsOneWidget,
        );
        expect(find.text(storyTitle), findsWidgets);
        expect(
          find.byKey(const ValueKey('story-narrative-body')),
          findsOneWidget,
        );
        expect(find.text(narrative), findsOneWidget);
        expect(
          find.byKey(const ValueKey('story-why-this-story')),
          findsOneWidget,
        );
        expect(find.text(rationale), findsWidgets);
      },
    );

    testWidgets('reflection Today behavior does not open Story Detail', (
      tester,
    ) async {
      await pumpHome(tester, experience: reflectionCandidate());

      expect(find.byKey(const ValueKey('today-why-this-story')), findsNothing);
      expect(find.text('Why this Story?'), findsNothing);
      expect(
        find.text(
          'You have been building consistency across your recent journey.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('today-experience-begin')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('begin-experience-button')));
      await tester.pumpAndSettle();

      expect(beginExperience.executeCount, 1);
      expect(find.byType(ReflectScreen), findsOneWidget);
      expect(find.byType(StoryDetailScreen), findsNothing);
    });

    testWidgets(
      'missing story target stays on Experience and does not invent a Story',
      (tester) async {
        await pumpHome(
          tester,
          experience: storyCandidate(targetId: null, id: 'adaptive-story-'),
        );

        await tester.tap(find.byKey(const ValueKey('today-experience-begin')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('begin-experience-button')));
        await tester.pump();

        expect(find.text('Story experience is unavailable.'), findsOneWidget);
        expect(find.byType(StoryDetailScreen), findsNothing);
        expect(find.byType(ExperienceScreen), findsOneWidget);
        expect(beginExperience.executeCount, 0);
      },
    );
  });

  group('Unavailable local Story', () {
    testWidgets(
      'candidate without a local Story fails closed with no fabricated content',
      (tester) async {
        await pumpHome(
          tester,
          experience: storyCandidate(
            id: 'adaptive-story-missing-local',
            targetId: 'missing-local',
            title: 'A Story That Is Not On This Device',
          ),
        );

        await openDetail(tester);

        final detail = tester.widget<StoryDetailScreen>(
          find.byType(StoryDetailScreen),
        );
        expect(detail.storyId, 'missing-local');
        expect(find.byKey(const ValueKey('story-unavailable')), findsOneWidget);
        expect(find.text('This story is not available.'), findsOneWidget);
        expect(find.byKey(const ValueKey('story-detail-title')), findsNothing);
        expect(
          find.byKey(const ValueKey('story-narrative-body')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('begin-story-consume')), findsNothing);
        expect(find.text(narrative), findsNothing);
        expect(find.text(writtenText), findsNothing);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(StoryDetailScreen), findsNothing);
        expect(find.byType(ExperienceScreen), findsOneWidget);
      },
    );
  });

  group('Story consumption', () {
    testWidgets('text-first written consumption is a valid path', (
      tester,
    ) async {
      await seedStory(representations: [writtenRep(writtenText)]);
      await pumpHome(tester, experience: storyCandidate());
      await openDetail(tester);

      await tester.tap(find.byKey(const ValueKey('begin-story-consume')));
      await tester.pumpAndSettle();

      expect(find.byType(StoryConsumeScreen), findsOneWidget);
      expect(find.text('Story Experience'), findsOneWidget);
      expect(find.byKey(const ValueKey('consume-text')), findsOneWidget);
      expect(find.text(writtenText), findsOneWidget);
      expect(find.byKey(const ValueKey('consume-media-meta')), findsNothing);
      expect(find.byKey(const ValueKey('reflect-on-story')), findsOneWidget);
      expect(find.byType(ReflectScreen), findsNothing);
    });

    testWidgets('missing media does not block text consumption or Reflect', (
      tester,
    ) async {
      await seedStory(representations: [audioWithoutBytes()]);
      final journey = DefaultCurrentJourneyContext()
        ..setCurrentJourney(journeyId);
      await pumpHome(tester, experience: storyCandidate(), journey: journey);
      await openDetail(tester);

      final begin = tester.widget<FilledButton>(
        find.byKey(const ValueKey('begin-story-consume')),
      );
      expect(begin.onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('begin-story-consume')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('consume-error')), findsNothing);
      expect(
        find.byKey(const ValueKey('consume-narrative-fallback')),
        findsOneWidget,
      );
      expect(find.text(narrative), findsWidgets);
      expect(find.byKey(const ValueKey('consume-media-meta')), findsNothing);
      expect(
        find.text('Spoken words that must not replace the narrative.'),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('complete-story-consume')));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(find.byType(ReflectScreen), findsNothing);
      expect(await reflections.findByJourneyId(journeyId), isEmpty);

      final completeButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('complete-story-consume')),
      );
      expect(completeButton.onPressed, isNull);
      final reflectButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('reflect-on-story')),
      );
      expect(reflectButton.onPressed, isNotNull);
    });

    testWidgets('incomplete Story content disables Begin story', (
      tester,
    ) async {
      await seedStory();
      await pumpHome(tester, experience: storyCandidate());
      await openDetail(tester);

      expect(find.text(narrative), findsOneWidget);
      final begin = tester.widget<FilledButton>(
        find.byKey(const ValueKey('begin-story-consume')),
      );
      expect(begin.onPressed, isNull);
      expect(find.byType(StoryConsumeScreen), findsNothing);
    });
  });

  group('Reflection boundary and Today refresh', () {
    testWidgets('viewing and completing a Story does not create evidence', (
      tester,
    ) async {
      await seedStory(representations: [writtenRep(writtenText)]);
      final container = await pumpHome(tester, experience: storyCandidate());
      await openDetail(tester);
      await tester.tap(find.byKey(const ValueKey('begin-story-consume')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('complete-story-consume')));
      await tester.pumpAndSettle();

      expect(find.byType(ReflectScreen), findsNothing);
      expect(await reflections.findByJourneyId(journeyId), isEmpty);
      final events = await container.read(eventStoreProvider).allEvents();
      expect(
        events.where((event) => event.event is ReflectionSubmitted),
        isEmpty,
      );
      expect(
        events.where((event) => event.event is BehavioralEvidenceDetected),
        isEmpty,
      );
      expect(todayBuilds, 1);
    });

    testWidgets(
      'explicit Reflection submit uses H.2 entry and refreshes Today',
      (tester) async {
        await seedStory(representations: [writtenRep(writtenText)]);
        final journey = DefaultCurrentJourneyContext()
          ..setCurrentJourney(journeyId);
        final container = await pumpHome(
          tester,
          experience: storyCandidate(),
          journey: journey,
        );

        await openDetail(tester);
        await tester.tap(find.byKey(const ValueKey('begin-story-consume')));
        await tester.pumpAndSettle();

        expect(find.byType(ReflectScreen), findsNothing);
        expect(await reflections.findByJourneyId(journeyId), isEmpty);

        await tester.tap(find.byKey(const ValueKey('reflect-on-story')));
        await tester.pumpAndSettle();

        expect(find.byType(ReflectScreen), findsOneWidget);
        final created = await reflections.findByJourneyId(journeyId);
        expect(created, hasLength(1));
        expect(created.single.journeyId, journeyId);
        expect(created.single.behavioralEvidence, isEmpty);
        expect(created.single.isSubmitted, isFalse);

        await tester.ensureVisible(
          find.byKey(const ValueKey('feeling-growing')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('feeling-growing')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('save-reflection')));
        await tester.tap(find.byKey(const Key('save-reflection')));
        await tester.pumpAndSettle();

        final submitted = await reflections.findByJourneyId(journeyId);
        expect(submitted.single.isSubmitted, isTrue);
        expect(submitted.single.behavioralEvidence, isEmpty);
        final events = await container.read(eventStoreProvider).allEvents();
        expect(
          events.where((event) => event.event is ReflectionSubmitted),
          hasLength(1),
        );
        expect(
          events.where((event) => event.event is BehavioralEvidenceDetected),
          isEmpty,
        );
        expect(todayBuilds, greaterThan(1));
        expect(find.text('Good morning.'), findsOneWidget);
        expect(find.byType(StoryConsumeScreen), findsNothing);
        expect(find.byType(ReflectScreen), findsNothing);
        expect(find.byType(StoryDetailScreen), findsNothing);
      },
    );

    testWidgets('Reflection cannot be entered without a current Journey', (
      tester,
    ) async {
      await seedStory(representations: [writtenRep(writtenText)]);
      await pumpHome(tester, experience: storyCandidate());
      await openDetail(tester);
      await tester.tap(find.byKey(const ValueKey('begin-story-consume')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reflect-on-story')));
      await tester.pump();

      expect(
        find.text('A journey is required before reflecting.'),
        findsOneWidget,
      );
      expect(find.byType(ReflectScreen), findsNothing);
      expect(await reflections.findByJourneyId(journeyId), isEmpty);
    });
  });
}

final class _CountingBeginExperienceUseCase implements BeginExperienceUseCase {
  _CountingBeginExperienceUseCase({required this.result});

  final Result<Reflection> result;
  int executeCount = 0;

  @override
  Future<Result<Reflection>> execute({required ExperienceAction action}) async {
    executeCount++;
    return result;
  }
}
