import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
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

  SourceSpanReference span(int start, int end) {
    return SourceSpanReference(
      representationId: transcriptId,
      startOffset: start,
      endOffset: end,
    );
  }

  StoryExperiencePlan buildPlan({
    List<StoryExperienceMoment>? keyMoments,
    List<StoryExperienceStep>? sequence,
    String coreMessage = 'A grounded core message.',
  }) {
    final moments = keyMoments ??
        [
          StoryExperienceMoment(
            id: 'km-1',
            description: 'The hard moment.',
            sourceSpan: span(0, 20),
          ),
        ];
    return StoryExperiencePlan(
      id: StoryExperiencePlanId('plan-1'),
      storyId: storyId,
      transcriptRepresentationId: transcriptId,
      intention: StoryExperienceIntention.inspire,
      coreMessage: coreMessage,
      emotionalArc: StoryExperienceArc.perseverance,
      keyMoments: moments,
      musicDirection: StoryExperienceMusicDirection(
        mood: 'hopeful',
        energy: 'steady',
        style: 'acoustic',
        rationale: 'Follows the story movement toward outcome.',
      ),
      reflectionPrompt: 'What stayed with you?',
      sequence: sequence ??
          [
            const StoryExperienceStep(type: StoryExperienceStepType.story),
            StoryExperienceStep(
              type: StoryExperienceStepType.keyMoment,
              referenceId: moments.first.id,
            ),
            const StoryExperienceStep(type: StoryExperienceStepType.reflection),
          ],
      createdAt: DateTime.utc(2026, 9, 24),
      providerLabel: 'test',
    );
  }

  test('valid plan construction', () {
    final plan = buildPlan();
    expect(plan.intention, StoryExperienceIntention.inspire);
    expect(plan.coreMessage, contains('grounded'));
    expect(plan.keyMoments, hasLength(1));
    expect(plan.sequence.first.type, StoryExperienceStepType.story);
    expect(plan.musicDirection.mood, 'hopeful');
  });

  test('rejects empty required fields', () {
    expect(
      () => buildPlan(coreMessage: '   '),
      throwsArgumentError,
    );
  });

  test('rejects invalid source span offsets on moment', () {
    expect(
      () => StoryExperienceMoment(
        id: 'km-bad',
        description: 'bad',
        sourceSpan: SourceSpanReference(
          representationId: transcriptId,
          startOffset: 10,
          endOffset: 5,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid sequence reference', () {
    expect(
      () => buildPlan(
        sequence: [
          const StoryExperienceStep(type: StoryExperienceStepType.story),
          const StoryExperienceStep(
            type: StoryExperienceStepType.keyMoment,
            referenceId: 'missing-moment',
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('rejects sequence without story-derived element', () {
    expect(
      () => buildPlan(
        sequence: const [
          StoryExperienceStep(type: StoryExperienceStepType.music),
          StoryExperienceStep(type: StoryExperienceStepType.reflection),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('assertSpansWithinTranscript rejects out-of-bounds spans', () {
    final plan = buildPlan(
      keyMoments: [
        StoryExperienceMoment(
          id: 'km-1',
          description: 'out of range',
          sourceSpan: span(0, 999),
        ),
      ],
      sequence: const [
        StoryExperienceStep(type: StoryExperienceStepType.story),
        StoryExperienceStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: 'km-1',
        ),
      ],
    );
    expect(
      () => plan.assertSpansWithinTranscript('short transcript'),
      throwsArgumentError,
    );
  });

  test('assertSpansWithinTranscript accepts in-bounds spans', () {
    final plan = buildPlan();
    final transcript = List.filled(40, 'a').join();
    expect(() => plan.assertSpansWithinTranscript(transcript), returnsNormally);
  });
}
