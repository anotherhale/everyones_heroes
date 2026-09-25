import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_provider_config.dart';

final class RunExperienceLabRequest {
  const RunExperienceLabRequest({
    required this.storyId,
    required this.ownerHeroId,
    this.config,
    this.forceRegenerate = false,
    this.targetDurationSeconds,
    this.occurredAt,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
  final ExperienceLabProviderConfig? config;
  final bool forceRegenerate;
  final int? targetDurationSeconds;
  final DateTime? occurredAt;
}
