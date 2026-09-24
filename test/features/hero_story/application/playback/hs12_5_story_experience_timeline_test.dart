import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_timeline.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_moment.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transcriptId = StoryRepresentationId('rep-transcript');
  final storyId = StoryId('story-1');

  StoryExperiencePlan threeMomentPlan() {
    final moments = [
      StoryExperienceMoment(
        id: 'km-1',
        description: 'Difficulty begins.',
        sourceSpan: SourceSpanReference(
          representationId: transcriptId,
          startOffset: 0,
          endOffset: 30,
        ),
      ),
      StoryExperienceMoment(
        id: 'km-2',
        description: 'Uncertainty.',
        sourceSpan: SourceSpanReference(
          representationId: transcriptId,
          startOffset: 30,
          endOffset: 60,
        ),
      ),
      StoryExperienceMoment(
        id: 'km-3',
        description: 'The decision.',
        sourceSpan: SourceSpanReference(
          representationId: transcriptId,
          startOffset: 60,
          endOffset: 90,
        ),
      ),
    ];
    return StoryExperiencePlan(
      id: StoryExperiencePlanId('plan-1'),
      storyId: storyId,
      transcriptRepresentationId: transcriptId,
      intention: StoryExperienceIntention.inspire,
      coreMessage: 'Step forward anyway.',
      emotionalArc: StoryExperienceArc.challenge,
      keyMoments: moments,
      musicDirection: StoryExperienceMusicDirection(
        mood: 'hopeful',
        energy: 'building',
        style: 'acoustic',
        rationale: 'Follows challenge toward decision.',
      ),
      reflectionPrompt: 'Where do you need to step forward?',
      sequence: [
        const StoryExperienceStep(type: StoryExperienceStepType.story),
        StoryExperienceStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: moments[0].id,
        ),
        StoryExperienceStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: moments[1].id,
        ),
        StoryExperienceStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: moments[2].id,
        ),
        const StoryExperienceStep(type: StoryExperienceStepType.music),
        const StoryExperienceStep(type: StoryExperienceStepType.reflection),
      ],
      createdAt: DateTime.utc(2026, 9, 24),
    );
  }

  const builder = StoryExperienceTimelineBuilder();
  const duration = Duration(seconds: 100);

  test('builds opening + ordered key-moment cues + closing', () {
    final timeline = builder.build(
      plan: threeMomentPlan(),
      recordingDuration: duration,
      transcriptLength: 90,
    );

    expect(timeline.cues, isNotEmpty);
    expect(timeline.cues.first.purpose, StoryExperiencePresentationPurpose.opening);
    expect(timeline.cues.first.stem, StoryExperienceDemoStem.quiet);

    final purposes = timeline.cues.map((c) => c.purpose).toList();
    expect(purposes, contains(StoryExperiencePresentationPurpose.challenge));
    expect(purposes, contains(StoryExperiencePresentationPurpose.uncertainty));
    expect(purposes, contains(StoryExperiencePresentationPurpose.decision));
    expect(purposes, contains(StoryExperiencePresentationPurpose.closing));
  });

  test('maps each supported presentation purpose to the correct stem', () {
    expect(
      stemForPresentationPurpose(StoryExperiencePresentationPurpose.opening),
      StoryExperienceDemoStem.quiet,
    );
    expect(
      stemForPresentationPurpose(StoryExperiencePresentationPurpose.challenge),
      StoryExperienceDemoStem.tension,
    );
    expect(
      stemForPresentationPurpose(StoryExperiencePresentationPurpose.uncertainty),
      StoryExperienceDemoStem.quiet,
    );
    expect(
      stemForPresentationPurpose(StoryExperiencePresentationPurpose.turningPoint),
      isNull,
    );
    expect(
      stemForPresentationPurpose(StoryExperiencePresentationPurpose.decision),
      StoryExperienceDemoStem.build,
    );
    expect(
      stemForPresentationPurpose(StoryExperiencePresentationPurpose.resolution),
      StoryExperienceDemoStem.expansive,
    );
    expect(
      stemForPresentationPurpose(StoryExperiencePresentationPurpose.closing),
      StoryExperienceDemoStem.resolve,
    );
  });

  test('honors sequence ordering via key-moment span positions', () {
    final timeline = builder.build(
      plan: threeMomentPlan(),
      recordingDuration: duration,
      transcriptLength: 90,
    );

    final keyCues = timeline.cues
        .where(
          (c) =>
              c.purpose == StoryExperiencePresentationPurpose.challenge ||
              c.purpose == StoryExperiencePresentationPurpose.uncertainty ||
              c.purpose == StoryExperiencePresentationPurpose.decision,
        )
        .toList();

    expect(keyCues, hasLength(3));
    expect(keyCues[0].at.inMilliseconds, lessThan(keyCues[1].at.inMilliseconds));
    expect(keyCues[1].at.inMilliseconds, lessThan(keyCues[2].at.inMilliseconds));
    // 0/90 → 0s, 30/90 → ~33s, 60/90 → ~66s
    expect(keyCues[0].at, Duration.zero);
    expect(keyCues[1].at.inSeconds, closeTo(33, 1));
    expect(keyCues[2].at.inSeconds, closeTo(66, 1));
  });

  test('inserts intentional silence for uncertainty without rewriting audio', () {
    final timeline = builder.build(
      plan: threeMomentPlan(),
      recordingDuration: duration,
      transcriptLength: 90,
    );
    final uncertainty = timeline.cues.firstWhere(
      (c) => c.purpose == StoryExperiencePresentationPurpose.uncertainty,
    );
    expect(uncertainty.hasSilence, isTrue);
    expect(
      uncertainty.silence.inMilliseconds,
      inInclusiveRange(
        StoryExperienceTimelineBuilder.minSilence.inMilliseconds,
        StoryExperienceTimelineBuilder.maxSilence.inMilliseconds,
      ),
    );
  });

  test('is deterministic for identical inputs', () {
    final plan = threeMomentPlan();
    final a = builder.build(
      plan: plan,
      recordingDuration: duration,
      transcriptLength: 90,
    );
    final b = builder.build(
      plan: plan,
      recordingDuration: duration,
      transcriptLength: 90,
    );
    expect(a.cues.length, b.cues.length);
    for (var i = 0; i < a.cues.length; i++) {
      expect(a.cues[i].at, b.cues[i].at);
      expect(a.cues[i].purpose, b.cues[i].purpose);
      expect(a.cues[i].stem, b.cues[i].stem);
      expect(a.cues[i].silence, b.cues[i].silence);
    }
  });

  test('rejects non-positive recording duration', () {
    expect(
      () => builder.build(
        plan: threeMomentPlan(),
        recordingDuration: Duration.zero,
      ),
      throwsArgumentError,
    );
  });

  test('uses recording timestamps when present on spans', () {
    final moments = [
      StoryExperienceMoment(
        id: 'km-1',
        description: 'Timed moment.',
        sourceSpan: SourceSpanReference(
          representationId: transcriptId,
          startOffset: 0,
          endOffset: 10,
          startTimestampMs: 5000,
          endTimestampMs: 8000,
        ),
      ),
    ];
    final plan = StoryExperiencePlan(
      id: StoryExperiencePlanId('plan-ts'),
      storyId: storyId,
      transcriptRepresentationId: transcriptId,
      intention: StoryExperienceIntention.inspire,
      coreMessage: 'Timed.',
      emotionalArc: StoryExperienceArc.challenge,
      keyMoments: moments,
      musicDirection: StoryExperienceMusicDirection(
        mood: 'calm',
        energy: 'low',
        style: 'pad',
        rationale: 'Uses recording timestamps.',
      ),
      reflectionPrompt: 'What stood out?',
      sequence: [
        const StoryExperienceStep(type: StoryExperienceStepType.story),
        StoryExperienceStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: moments.first.id,
        ),
      ],
      createdAt: DateTime.utc(2026, 9, 24),
    );

    final timeline = builder.build(
      plan: plan,
      recordingDuration: const Duration(seconds: 20),
    );
    final cue = timeline.cues.firstWhere(
      (c) => c.purpose == StoryExperiencePresentationPurpose.turningPoint,
    );
    expect(cue.at, const Duration(seconds: 5));
  });
}
