import 'dart:io';

import 'package:everyonesheroes/app/presentation/theme/app_theme.dart';
import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/captured_story_reading_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_experience_planner_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_transcription_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/original_recording_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/playback/story_experience_player_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/recording/recording_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/captured_story_reading_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/transcription/transcription_store_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/capture_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/recording/device_recording_port.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/transcription_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_moment.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_step.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_experience_planner_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/fake_original_recording_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/fake_story_experience_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_experience_plan_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_understanding_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/tell_your_story_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/tell_your_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryStoryMediaStorageAdapter media;
  late InMemoryCaptureCompletionStore completionStore;
  late InMemoryStoryTranscriptionJobStore jobStore;
  late InMemoryTranscriptionCompletionStore transcriptionCompletionStore;
  late InMemoryCapturedStoryReadingRepository readings;
  late InMemoryStoryExperiencePlanRepository plans;
  late InMemoryStoryTranscriptionAdapter transcriptionAdapter;
  late CapturedStoryReadingPort readingAdapter;
  late StoryExperiencePlannerPort plannerAdapter;
  late FakeDeviceRecordingAdapter recorder;
  late FakeOriginalRecordingPlayer originalPlayer;
  late FakeStoryExperiencePlayer experiencePlayer;
  late Directory tempDir;
  late HeroId heroId;

  const storyTitle = 'Stepping Forward';

  setUp(() async {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    media = InMemoryStoryMediaStorageAdapter();
    completionStore = InMemoryCaptureCompletionStore();
    jobStore = InMemoryStoryTranscriptionJobStore();
    transcriptionCompletionStore = InMemoryTranscriptionCompletionStore();
    readings = InMemoryCapturedStoryReadingRepository();
    plans = InMemoryStoryExperiencePlanRepository();
    transcriptionAdapter = InMemoryStoryTranscriptionAdapter();
    readingAdapter = InMemoryCapturedStoryReadingAdapter();
    plannerAdapter = InMemoryStoryExperiencePlannerAdapter();
    tempDir = Directory.systemTemp.createTempSync('hs12-5-ui-');
    recorder = FakeDeviceRecordingAdapter(
      outputDirectory: tempDir,
      initialPermission: DevicePermissionStatus.granted,
      fakeBytes: 'original-captured-recording',
    );
    originalPlayer = FakeOriginalRecordingPlayer();
    experiencePlayer = FakeStoryExperiencePlayer();
    heroId = HeroId.generate();

    await heroes.save(
      hs.Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Local Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      ),
    );
  });

  tearDown(() async {
    await experiencePlayer.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        storyMediaStoragePortProvider.overrideWithValue(media),
        captureCompletionStoreProvider.overrideWithValue(completionStore),
        storyTranscriptionJobStoreProvider.overrideWithValue(jobStore),
        transcriptionCompletionStoreProvider.overrideWithValue(
          transcriptionCompletionStore,
        ),
        capturedStoryReadingRepositoryProvider.overrideWithValue(readings),
        storyExperiencePlanRepositoryProvider.overrideWithValue(plans),
        storyTranscriptionPortProvider.overrideWithValue(transcriptionAdapter),
        capturedStoryReadingPortProvider.overrideWithValue(readingAdapter),
        storyExperiencePlannerPortProvider.overrideWithValue(plannerAdapter),
        eventBusProvider.overrideWithValue(
          InMemoryEventBus(
            eventStore: InMemoryEventStore(),
            dispatcher: InMemoryEventDispatcher(),
          ),
        ),
        useRealDeviceRecordingProvider.overrideWithValue(false),
        deviceRecordingPortProvider.overrideWithValue(recorder),
        activeLocalHeroStoreProvider.overrideWithValue(ActiveLocalHeroStore()),
        originalRecordingPlayerFactoryProvider.overrideWithValue(
          FakeOriginalRecordingPlayerFactory(originalPlayer),
        ),
        storyExperiencePlayerFactoryProvider.overrideWithValue(
          FakeStoryExperiencePlayerFactory(experiencePlayer),
        ),
      ],
    );
  }

  Future<void> captureThroughHeroStory(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const _PreviousScreen(),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-tell-your-story')));
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 40; i++) {
        final phase = container.read(tellYourStoryControllerProvider).phase;
        if (phase.name != 'idle') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      final controller = container.read(
        tellYourStoryControllerProvider.notifier,
      );
      controller.continueToRecord();
      await controller.startRecording();
      await controller.stopRecording();
      controller.updateTitle(storyTitle);
      await controller.acceptRecording();
      controller.setGrantProcessing(true);
      controller.setGrantAiTransformation(true);
      await controller.submitConsent();
    });
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('capture-view-story-button')));
    await tester.pumpAndSettle();
  }

  Future<String> understandStory(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    final storyId = (await stories.findAll()).single.id.value;
    await tester.tap(
      find.byKey(const ValueKey('hero-story-understand-button')),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        final phase =
            container.read(heroStoryUnderstandingProvider(storyId)).phase;
        if (phase == HeroStoryUnderstandingPhase.ready ||
            phase == HeroStoryUnderstandingPhase.failed) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();
    return storyId;
  }

  Future<void> createExperience(
    WidgetTester tester,
    ProviderContainer container,
    String storyId,
  ) async {
    await tester.drag(
      find.byKey(const ValueKey('hero-story-screen')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('hero-story-create-experience-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('hero-story-create-experience-button')),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        final phase =
            container.read(heroStoryExperiencePlanProvider(storyId)).phase;
        if (phase == HeroStoryExperiencePlanPhase.success ||
            phase == HeroStoryExperiencePlanPhase.failed) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Create my experience when no plan; Play my experience when plan exists',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await captureThroughHeroStory(tester, container);
      final storyId = await understandStory(tester, container);

      await tester.drag(
        find.byKey(const ValueKey('hero-story-screen')),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      expect(find.text('Create my experience'), findsOneWidget);
      expect(find.text('Play my experience'), findsNothing);

      await createExperience(tester, container, storyId);
      expect(
        container.read(heroStoryExperiencePlanProvider(storyId)).phase,
        HeroStoryExperiencePlanPhase.success,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('hero-story-play-experience-button')),
      );
      expect(find.text('Play my experience'), findsOneWidget);
      expect(find.text('Refresh experience plan'), findsOneWidget);
    },
  );

  testWidgets(
    'Play my experience loads persisted plan without regenerating',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await captureThroughHeroStory(tester, container);
      final storyId = await understandStory(tester, container);
      await createExperience(tester, container, storyId);

      final planBefore = await plans.findByStoryId(StoryId(storyId));
      expect(planBefore, isNotNull);
      final planIdBefore = planBefore!.id;

      await tester.ensureVisible(
        find.byKey(const ValueKey('hero-story-play-experience-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('hero-story-play-experience-button')),
      );
      await tester.pumpAndSettle();

      expect(
        experiencePlayer.calls,
        containsAllInOrder(<String>['load', 'play']),
      );
      expect(experiencePlayer.loadedPlan?.id, planIdBefore);
      expect(experiencePlayer.invokedAi, isFalse);
      expect(experiencePlayer.regeneratedPlan, isFalse);

      final planAfter = await plans.findByStoryId(StoryId(storyId));
      expect(planAfter?.id, planIdBefore);

      expect(find.text('Stop experience'), findsOneWidget);
      expect(find.text('Pause experience'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('hero-story-experience-stop-button')),
      );
      await tester.pumpAndSettle();
      expect(experiencePlayer.calls, contains('stop'));
    },
  );

  testWidgets(
    'original recording remains available during and after experience',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await captureThroughHeroStory(tester, container);
      final storyId = await understandStory(tester, container);
      await createExperience(tester, container, storyId);

      await tester.ensureVisible(
        find.byKey(const ValueKey('hero-story-play-experience-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('hero-story-play-experience-button')),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('hero-story-screen')),
        const Offset(0, 1200),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('hero-story-play-button')),
      );

      await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
      await tester.pumpAndSettle();
      expect(
        originalPlayer.calls,
        containsAllInOrder(<String>['load', 'play']),
      );
      expect(experiencePlayer.calls, contains('stop'));
    },
  );

  testWidgets('experience error leaves original playback available', (
    tester,
  ) async {
    experiencePlayer.failOnPlay = true;
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    final storyId = await understandStory(tester, container);
    await createExperience(tester, container, storyId);

    await tester.ensureVisible(
      find.byKey(const ValueKey('hero-story-play-experience-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('hero-story-play-experience-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hero-story-experience-playback-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('hero-story-experience-playback-error-recording'),
      ),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hero-story-screen')),
      const Offset(0, 1200),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('hero-story-play-button')),
    );
    await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.pumpAndSettle();
    expect(originalPlayer.calls, contains('play'));
  });

  testWidgets('missing plan fails safely and keeps original recording', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    final storyId = await understandStory(tester, container);
    await createExperience(tester, container, storyId);

    final existing = await plans.findByStoryId(StoryId(storyId));
    expect(existing, isNotNull);
    await plans.delete(existing!.id);

    await tester.ensureVisible(
      find.byKey(const ValueKey('hero-story-play-experience-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('hero-story-play-experience-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hero-story-experience-playback-error')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hero-story-screen')),
      const Offset(0, 1200),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('hero-story-play-button')),
    );
    await tester.tap(find.byKey(const ValueKey('hero-story-play-button')));
    await tester.pumpAndSettle();
    expect(originalPlayer.calls, contains('play'));
  });

  testWidgets('Story remains unchanged after experience play', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    final storyId = await understandStory(tester, container);
    await createExperience(tester, container, storyId);

    final storyBefore = await stories.findById(StoryId(storyId));
    expect(storyBefore, isNotNull);
    final titleBefore = storyBefore!.title.value;
    final narrativeBefore = storyBefore.narrative.value;
    final representationsBefore = storyBefore.representations.length;
    final readingBefore = await readings.findByStoryId(StoryId(storyId));

    await tester.ensureVisible(
      find.byKey(const ValueKey('hero-story-play-experience-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('hero-story-play-experience-button')),
    );
    await tester.pumpAndSettle();

    final storyAfter = await stories.findById(StoryId(storyId));
    expect(storyAfter?.title.value, titleBefore);
    expect(storyAfter?.narrative.value, narrativeBefore);
    expect(storyAfter?.representations.length, representationsBefore);
    final readingAfter = await readings.findByStoryId(StoryId(storyId));
    expect(readingAfter?.id, readingBefore?.id);
    expect(experiencePlayer.loadedBytes, isNotNull);
  });

  testWidgets('back navigation remains functional from Hero Story', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await captureThroughHeroStory(tester, container);
    expect(find.byKey(const ValueKey('hero-story-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('hero-story-app-bar')), findsOneWidget);

    final navigator = Navigator.of(
      tester.element(find.byKey(const ValueKey('hero-story-screen'))),
    );
    // Capture pushes Hero Story onto the stack; back must remain available.
    expect(navigator.canPop(), isTrue);
  });

  test('invalid plan is rejected at domain boundary, not silently repaired', () {
    final transcriptId = StoryRepresentationId('t1');
    expect(
      () => StoryExperiencePlan(
        id: StoryExperiencePlanId('bad'),
        storyId: StoryId('s1'),
        transcriptRepresentationId: transcriptId,
        intention: StoryExperienceIntention.inspire,
        coreMessage: 'x',
        emotionalArc: StoryExperienceArc.challenge,
        keyMoments: [
          StoryExperienceMoment(
            id: 'km-1',
            description: 'ok',
            sourceSpan: SourceSpanReference(
              representationId: transcriptId,
              startOffset: 0,
              endOffset: 1,
            ),
          ),
        ],
        musicDirection: StoryExperienceMusicDirection(
          mood: 'm',
          energy: 'e',
          style: 's',
          rationale: 'r',
        ),
        reflectionPrompt: 'p',
        sequence: const [
          StoryExperienceStep(type: StoryExperienceStepType.music),
        ],
        createdAt: DateTime.utc(2026, 9, 24),
      ),
      throwsArgumentError,
    );
  });
}

class _PreviousScreen extends StatelessWidget {
  const _PreviousScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: const ValueKey('open-tell-your-story'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TellYourStoryScreen(),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}
