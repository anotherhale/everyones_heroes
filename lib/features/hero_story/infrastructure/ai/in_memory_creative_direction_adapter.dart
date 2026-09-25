import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Deterministic [CreativeDirectionPort] for tests and local development.
final class InMemoryCreativeDirectionAdapter implements CreativeDirectionPort {
  InMemoryCreativeDirectionAdapter({
    this.failWith,
    this.delay = Duration.zero,
    this.overrideDirection,
  });

  CreativeDirectionException? failWith;
  Duration delay;
  PresentationCreativeDirection? overrideDirection;

  int callCount = 0;
  CreativeDirectionRequest? lastRequest;

  @override
  Future<PresentationCreativeDirection> direct(
    CreativeDirectionRequest request,
  ) async {
    callCount += 1;
    lastRequest = request;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (failWith != null) {
      throw failWith!;
    }

    if (overrideDirection != null) {
      return overrideDirection!;
    }

    final progression = <CreativeIntensityStep>[
      CreativeIntensityStep(
        purpose: StoryExperiencePresentationPurpose.opening,
        intensity: MusicIntensityLabel.quiet,
        guidance: 'Restrained opening under the Hero voice',
      ),
      CreativeIntensityStep(
        purpose: StoryExperiencePresentationPurpose.challenge,
        intensity: MusicIntensityLabel.tension,
        guidance: 'Gradual tension as challenge emerges',
      ),
      CreativeIntensityStep(
        purpose: StoryExperiencePresentationPurpose.uncertainty,
        intensity: MusicIntensityLabel.quiet,
        guidance: 'Hold back during uncertainty',
      ),
      CreativeIntensityStep(
        purpose: StoryExperiencePresentationPurpose.turningPoint,
        intensity: MusicIntensityLabel.quiet,
        guidance: 'Dip toward silence at the turning point',
      ),
      CreativeIntensityStep(
        purpose: StoryExperiencePresentationPurpose.decision,
        intensity: MusicIntensityLabel.build,
        guidance: 'Hopeful build as decision forms',
      ),
      CreativeIntensityStep(
        purpose: StoryExperiencePresentationPurpose.resolution,
        intensity: MusicIntensityLabel.expansive,
        guidance: 'Expansive emotional peak at resolution',
      ),
      CreativeIntensityStep(
        purpose: StoryExperiencePresentationPurpose.closing,
        intensity: MusicIntensityLabel.resolve,
        guidance: 'Warm resolved ending',
      ),
    ];

    final music = request.musicDirection;
    final brief = [
      'instrumental cinematic ${music.style} underscore',
      '${music.mood} mood',
      '${music.energy} energy',
      'restrained opening',
      'gradual tension',
      'hopeful build',
      'expansive emotional peak',
      'warm resolved ending',
      'no vocals',
      'no lyrics',
    ].join(', ');

    return PresentationCreativeDirection(
      narrationEmphasis:
          'Emphasize the grounded core message: ${request.coreMessage}',
      pacingGuidance:
          'Follow ${request.emotionalArc.name} arc with measured pacing; '
          'pause before turning point.',
      pauses: const [
        'Brief pause before turning point',
        'Soft hold before closing reflection',
      ],
      intensityProgression: progression,
      musicPromptBrief: brief,
      transitionNotes: const [
        'Duck music under speech',
        'Rise during intentional silence only if purpose allows',
      ],
      providerLabel: 'in_memory_creative_direction',
      modelLabel: 'fake-creative',
      processingVersion: request.processingVersion ??
          PresentationCreativeDirection.defaultProcessingVersion,
    );
  }

  /// Convenience builder when a full plan is available in tests.
  static CreativeDirectionRequest requestFromPlan(StoryExperiencePlan plan) {
    return CreativeDirectionRequest(
      storyId: plan.storyId,
      experiencePlanId: plan.id,
      experiencePlanProcessingVersion: plan.processingVersion,
      intention: plan.intention,
      coreMessage: plan.coreMessage,
      emotionalArc: plan.emotionalArc,
      musicDirection: plan.musicDirection,
      keyMomentLabels: plan.keyMoments.map((m) => m.description).toList(),
      sequenceStepTypes: plan.sequence.map((s) => s.type.name).toList(),
      reflectionPrompt: plan.reflectionPrompt,
    );
  }
}
