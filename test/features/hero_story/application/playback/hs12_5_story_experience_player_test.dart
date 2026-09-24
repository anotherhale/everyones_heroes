import 'dart:typed_data';

import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_player.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_moment.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_step.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/fake_story_experience_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transcriptId = StoryRepresentationId('rep-transcript');
  final storyId = StoryId('story-1');

  StoryExperiencePlan samplePlan() {
    final moments = [
      StoryExperienceMoment(
        id: 'km-1',
        description: 'Hard part.',
        sourceSpan: SourceSpanReference(
          representationId: transcriptId,
          startOffset: 0,
          endOffset: 40,
        ),
      ),
      StoryExperienceMoment(
        id: 'km-2',
        description: 'Doubt.',
        sourceSpan: SourceSpanReference(
          representationId: transcriptId,
          startOffset: 40,
          endOffset: 80,
        ),
      ),
      StoryExperienceMoment(
        id: 'km-3',
        description: 'Choice.',
        sourceSpan: SourceSpanReference(
          representationId: transcriptId,
          startOffset: 80,
          endOffset: 120,
        ),
      ),
    ];
    return StoryExperiencePlan(
      id: StoryExperiencePlanId('plan-1'),
      storyId: storyId,
      transcriptRepresentationId: transcriptId,
      intention: StoryExperienceIntention.inspire,
      coreMessage: 'Keep going.',
      emotionalArc: StoryExperienceArc.perseverance,
      keyMoments: moments,
      musicDirection: StoryExperienceMusicDirection(
        mood: 'hopeful',
        energy: 'steady',
        style: 'acoustic',
        rationale: 'Supports perseverance.',
      ),
      reflectionPrompt: 'What would perseverance look like today?',
      sequence: [
        const StoryExperienceStep(type: StoryExperienceStepType.story),
        for (final m in moments)
          StoryExperienceStep(
            type: StoryExperienceStepType.keyMoment,
            referenceId: m.id,
          ),
        const StoryExperienceStep(type: StoryExperienceStepType.reflection),
      ],
      createdAt: DateTime.utc(2026, 9, 24),
    );
  }

  late FakeStoryExperiencePlayer player;
  late StoryExperiencePlan plan;
  late Uint8List recordingBytes;

  setUp(() {
    player = FakeStoryExperiencePlayer(
      recordingDuration: const Duration(seconds: 30),
    );
    plan = samplePlan();
    recordingBytes = Uint8List.fromList(
      List<int>.generate(64, (i) => i),
    );
  });

  tearDown(() async {
    await player.dispose();
  });

  test('loads persisted plan and starts original recording', () async {
    await player.load(
      originalRecordingBytes: recordingBytes,
      plan: plan,
      transcriptLength: 120,
    );
    await player.play();

    expect(player.calls, containsAllInOrder(<String>['load', 'play']));
    expect(player.loadedBytes, equals(recordingBytes));
    expect(player.loadedPlan?.id, plan.id);
    expect(player.timeline, isNotNull);
    expect(player.currentStem, StoryExperienceDemoStem.quiet);
    expect(
      player.currentPurpose,
      StoryExperiencePresentationPurpose.opening,
    );
  });

  test('starts appropriate demo stem for opening', () async {
    await player.load(originalRecordingBytes: recordingBytes, plan: plan);
    final phases = <StoryExperiencePlaybackPhase>[];
    final sub = player.snapshots.listen((s) => phases.add(s.phase));
    await player.play();
    await sub.cancel();

    expect(phases, contains(StoryExperiencePlaybackPhase.playing));
    expect(player.currentStem, StoryExperienceDemoStem.quiet);
  });

  test('maps sequence cues to stems in order', () async {
    await player.load(
      originalRecordingBytes: recordingBytes,
      plan: plan,
      transcriptLength: 120,
    );
    await player.play();

    // Cue 0 = opening (already applied on play). Advance through key moments.
    player.advanceToCue(1); // challenge → tension
    expect(player.currentStem, StoryExperienceDemoStem.tension);
    expect(
      player.calls,
      contains('cue:challenge:tension'),
    );

    player.advanceToCue(2); // uncertainty → quiet + silence
    expect(player.currentStem, StoryExperienceDemoStem.quiet);
    expect(player.calls.any((c) => c.startsWith('silence:')), isTrue);

    player.advanceToCue(3); // decision → build
    expect(player.currentStem, StoryExperienceDemoStem.build);
  });

  test('pause resume stop and completion', () async {
    await player.load(originalRecordingBytes: recordingBytes, plan: plan);
    await player.play();
    await player.pause();
    expect(player.calls, contains('pause'));
    await player.play();
    expect(player.calls.where((c) => c == 'play').length, greaterThanOrEqualTo(2));
    await player.stop();
    expect(player.calls, contains('stop'));
    expect(player.currentStem, isNull);

    await player.play();
    player.completePlayback();
    expect(player.calls, contains('completed'));
  });

  test('playback failure surfaces failed phase', () async {
    await player.load(originalRecordingBytes: recordingBytes, plan: plan);
    StoryExperiencePlaybackPhase? seen;
    final sub = player.snapshots.listen((s) => seen = s.phase);
    // Allow subscription to attach to the broadcast stream.
    await Future<void>.delayed(Duration.zero);
    player.failPlayback('stem missing');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(seen, StoryExperiencePlaybackPhase.failed);
  });

  test('missing stem does not mutate original recording bytes', () async {
    await player.load(originalRecordingBytes: recordingBytes, plan: plan);
    final before = Uint8List.fromList(player.loadedBytes!);
    // Simulate missing stem by advancing; fake keeps bytes intact.
    player.advanceToCue(1);
    expect(player.loadedBytes, equals(before));
    expect(identical(player.loadedBytes, recordingBytes), isFalse);
  });

  test('does not invoke AI or regenerate plan during playback', () async {
    await player.load(originalRecordingBytes: recordingBytes, plan: plan);
    await player.play();
    player.advanceToCue(1);
    await player.pause();
    await player.play();
    await player.stop();

    expect(player.invokedAi, isFalse);
    expect(player.regeneratedPlan, isFalse);
    expect(player.loadedPlan?.id, plan.id);
  });

  test('rejects empty original recording', () async {
    expect(
      () => player.load(
        originalRecordingBytes: Uint8List(0),
        plan: plan,
      ),
      throwsStateError,
    );
  });

  test('play without load fails', () async {
    expect(player.play, throwsStateError);
  });

  test('failOnLoad and failOnPlay', () async {
    player.failOnLoad = true;
    expect(
      () => player.load(originalRecordingBytes: recordingBytes, plan: plan),
      throwsStateError,
    );

    player.failOnLoad = false;
    player.failOnPlay = true;
    await player.load(originalRecordingBytes: recordingBytes, plan: plan);
    expect(player.play, throwsStateError);
  });

  test('demo stem asset paths are stable and local', () {
    for (final stem in StoryExperienceDemoStem.values) {
      final path = StoryExperienceDemoStemAssets.assetPath(stem);
      expect(path, startsWith('assets/audio/demo_stems/'));
      expect(path, endsWith('${stem.name}.wav'));
    }
    expect(
      StoryExperienceDemoStemAssets.allAssetPaths,
      hasLength(StoryExperienceDemoStem.values.length),
    );
  });
}
