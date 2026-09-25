import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';

/// Provider-independent creative-direction boundary for Experiment A.
///
/// Transforms an existing [StoryExperiencePlan] into presentation guidance.
/// Does not mutate Story, CapturedStoryReading, or StoryExperiencePlan.
/// Must not infer personality, psychology, diagnosis, or behavioral traits.
abstract interface class CreativeDirectionPort {
  Future<PresentationCreativeDirection> direct(
    CreativeDirectionRequest request,
  );
}

/// Minimum grounded inputs for creative presentation direction.
final class CreativeDirectionRequest {
  const CreativeDirectionRequest({
    required this.storyId,
    required this.experiencePlanId,
    required this.experiencePlanProcessingVersion,
    required this.intention,
    required this.coreMessage,
    required this.emotionalArc,
    required this.musicDirection,
    required this.keyMomentLabels,
    required this.sequenceStepTypes,
    this.reflectionPrompt,
    this.targetDurationSeconds,
    this.processingVersion,
    this.providerHint,
    this.modelHint,
  });

  final StoryId storyId;
  final StoryExperiencePlanId experiencePlanId;
  final String experiencePlanProcessingVersion;
  final StoryExperienceIntention intention;
  final String coreMessage;
  final StoryExperienceArc emotionalArc;
  final StoryExperienceMusicDirection musicDirection;
  final List<String> keyMomentLabels;
  final List<String> sequenceStepTypes;
  final String? reflectionPrompt;
  final int? targetDurationSeconds;
  final String? processingVersion;
  final String? providerHint;
  final String? modelHint;
}

final class CreativeDirectionException implements Exception {
  const CreativeDirectionException(this.message);

  final String message;

  @override
  String toString() => 'CreativeDirectionException: $message';
}
