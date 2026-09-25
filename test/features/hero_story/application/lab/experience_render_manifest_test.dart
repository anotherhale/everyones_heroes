import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest_builder.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_timeline.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_provider_config.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_moment.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transcriptId = StoryRepresentationId('rep-transcript');
  final storyId = StoryId('story-1');
  const timelineBuilder = StoryExperienceTimelineBuilder();
  const manifestBuilder = ExperienceRenderManifestBuilder();
  const duration = Duration(seconds: 100);

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

  test('valid manifest can be built from timeline + music id', () {
    final plan = threeMomentPlan();
    final timeline = timelineBuilder.build(
      plan: plan,
      recordingDuration: duration,
      transcriptLength: 90,
    );
    final musicId = MusicRenderingId('music-1');
    final voiceId = StoryVoiceRenderingId('voice-1');
    final config = ExperienceLabProviderConfig.experimentA();

    final manifest = manifestBuilder.build(
      plan: plan,
      timeline: timeline,
      config: config,
      musicRenderingId: musicId,
      voiceRenderingId: voiceId,
      creativeDirection: PresentationCreativeDirection(
        narrationEmphasis: 'Ground the message.',
        pacingGuidance: 'Measured pacing.',
        intensityProgression: [
          CreativeIntensityStep(
            purpose: StoryExperiencePresentationPurpose.opening,
            intensity: MusicIntensityLabel.quiet,
          ),
          CreativeIntensityStep(
            purpose: StoryExperiencePresentationPurpose.decision,
            intensity: MusicIntensityLabel.build,
          ),
        ],
        musicPromptBrief:
            'instrumental acoustic underscore, no vocals, no lyrics',
      ),
      createdAt: DateTime.utc(2026, 9, 25),
    );

    expect(manifest.storyId, storyId);
    expect(manifest.experiencePlanId, plan.id);
    expect(manifest.musicRenderingId, musicId);
    expect(manifest.voiceRenderingId, voiceId);
    expect(manifest.hasRequiredArtifacts, isTrue);
    expect(manifest.missingArtifactLabels(), isEmpty);
    expect(manifest.cues, isNotEmpty);
    expect(manifest.cues.length, timeline.cues.length);
    expect(manifest.providerConfigFingerprint, config.fingerprint);
  });

  test('missing artifacts detected via missingArtifactLabels', () {
    final plan = threeMomentPlan();
    final timeline = timelineBuilder.build(
      plan: plan,
      recordingDuration: duration,
      transcriptLength: 90,
    );

    final withoutMusic = manifestBuilder.build(
      plan: plan,
      timeline: timeline,
      config: ExperienceLabProviderConfig.experimentA(),
      musicRenderingId: null,
      recordingRole: ExperienceRenderRecordingRole.narrated,
      createdAt: DateTime.utc(2026, 9, 25),
    );

    expect(withoutMusic.hasRequiredArtifacts, isFalse);
    expect(
      withoutMusic.missingArtifactLabels(),
      containsAll(['musicRendering', 'voiceRendering']),
    );
  });

  test('MusicRendering associated via single musicRenderingId — no multi-clip',
      () {
    final plan = threeMomentPlan();
    final timeline = timelineBuilder.build(
      plan: plan,
      recordingDuration: duration,
      transcriptLength: 90,
    );
    final musicId = MusicRenderingId('music-only');

    final manifest = manifestBuilder.build(
      plan: plan,
      timeline: timeline,
      config: ExperienceLabProviderConfig.experimentA(),
      musicRenderingId: musicId,
      createdAt: DateTime.utc(2026, 9, 25),
    );

    expect(manifest.musicRenderingId, musicId);
    // Strategy A: one bed id; cues carry volume automation, not clip lists.
    expect(manifest.cues.every((c) => c.musicVolume >= 0 && c.musicVolume <= 1),
        isTrue);
    expect(
      manifest.cues.map((c) => c.purpose).toSet().length,
      greaterThan(1),
    );
  });

  test('timeline from StoryExperienceTimelineBuilder remains valid', () {
    final plan = threeMomentPlan();
    final timeline = timelineBuilder.build(
      plan: plan,
      recordingDuration: duration,
      transcriptLength: 90,
    );

    expect(timeline.cues, isNotEmpty);
    expect(
      timeline.cues.first.purpose,
      StoryExperiencePresentationPurpose.opening,
    );
    final purposes = timeline.cues.map((c) => c.purpose).toList();
    expect(purposes, contains(StoryExperiencePresentationPurpose.challenge));
    expect(purposes, contains(StoryExperiencePresentationPurpose.decision));
    expect(purposes, contains(StoryExperiencePresentationPurpose.closing));

    final manifest = manifestBuilder.build(
      plan: plan,
      timeline: timeline,
      config: ExperienceLabProviderConfig.experimentA(),
      musicRenderingId: MusicRenderingId('music-1'),
      createdAt: DateTime.utc(2026, 9, 25),
    );
    expect(manifest.cues.map((c) => c.at).toList(),
        timeline.cues.map((c) => c.at).toList());
    expect(manifest.cues.map((c) => c.purpose).toList(), purposes);
  });
}
