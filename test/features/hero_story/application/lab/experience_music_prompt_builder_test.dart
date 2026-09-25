import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_music_prompt_builder.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
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

  StoryExperiencePlan samplePlan() {
    return StoryExperiencePlan(
      id: StoryExperiencePlanId('plan-1'),
      storyId: StoryId('story-1'),
      transcriptRepresentationId: transcriptId,
      intention: StoryExperienceIntention.inspire,
      coreMessage: 'Step forward anyway.',
      emotionalArc: StoryExperienceArc.challenge,
      keyMoments: [
        StoryExperienceMoment(
          id: 'km-1',
          description: 'The challenge begins.',
          sourceSpan: SourceSpanReference(
            representationId: transcriptId,
            startOffset: 0,
            endOffset: 20,
          ),
        ),
      ],
      musicDirection: StoryExperienceMusicDirection(
        mood: 'hopeful',
        energy: 'building',
        style: 'acoustic',
        rationale: 'Supports challenge toward decision.',
      ),
      reflectionPrompt: 'Where do you need to step forward?',
      sequence: const [
        StoryExperienceStep(type: StoryExperienceStepType.story),
        StoryExperienceStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: 'km-1',
        ),
        StoryExperienceStep(type: StoryExperienceStepType.music),
      ],
      createdAt: DateTime.utc(2026, 9, 24),
    );
  }

  test('derives prompt from experience musicDirection when no creative brief',
      () {
    final prompt = ExperienceMusicPromptBuilder.build(plan: samplePlan());

    expect(prompt.toLowerCase(), contains('acoustic'));
    expect(prompt.toLowerCase(), contains('hopeful'));
    expect(prompt.toLowerCase(), contains('building'));
    expect(prompt.toLowerCase(), contains('instrumental'));
    expect(prompt.toLowerCase(), contains('no vocals'));
    expect(prompt.toLowerCase(), contains('no lyrics'));
  });

  test('prefers creative-direction musicPromptBrief and keeps instrumental',
      () {
    final direction = PresentationCreativeDirection(
      narrationEmphasis: 'Ground the core message.',
      pacingGuidance: 'Measured pace.',
      intensityProgression: [
        CreativeIntensityStep(
          purpose: StoryExperiencePresentationPurpose.opening,
          intensity: MusicIntensityLabel.quiet,
        ),
      ],
      musicPromptBrief:
          'cinematic pad underscore, restrained opening, hopeful build, '
          'no vocals',
    );

    final prompt = ExperienceMusicPromptBuilder.build(
      plan: samplePlan(),
      creativeDirection: direction,
    );

    expect(prompt, contains('cinematic pad underscore'));
    expect(prompt.toLowerCase(), contains('instrumental'));
    expect(prompt.toLowerCase(), contains('no vocals'));
    expect(prompt.toLowerCase(), contains('no lyrics'));
  });

  test('instrumental constraint present even when brief already mentions it',
      () {
    final direction = PresentationCreativeDirection(
      narrationEmphasis: 'Ground the core message.',
      pacingGuidance: 'Measured pace.',
      intensityProgression: [
        CreativeIntensityStep(
          purpose: StoryExperiencePresentationPurpose.closing,
          intensity: MusicIntensityLabel.resolve,
        ),
      ],
      musicPromptBrief:
          'instrumental ambient bed, no vocals, no lyrics, warm resolve',
    );

    final prompt = ExperienceMusicPromptBuilder.build(
      plan: samplePlan(),
      creativeDirection: direction,
    );

    expect(prompt.toLowerCase(), contains('instrumental'));
    expect(prompt.toLowerCase(), contains('no vocals'));
    expect(prompt.toLowerCase(), contains('no lyrics'));
  });
}
