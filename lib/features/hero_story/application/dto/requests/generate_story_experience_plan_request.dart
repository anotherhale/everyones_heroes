import 'package:everyonesheroes/core/ids/story_id.dart';

/// Application request to generate a derived Story Experience Plan (HS.12.4).
final class GenerateStoryExperiencePlanAppRequest {
  const GenerateStoryExperiencePlanAppRequest({
    required this.storyId,
    this.processingVersion = 'hs12.4.v1',
    this.occurredAt,
    this.forceRegenerate = true,
  });

  final StoryId storyId;
  final String processingVersion;
  final DateTime? occurredAt;

  /// When false and a plan already exists for the story, return it without
  /// calling the planner. Regeneration is the default for HS.12.4.
  final bool forceRegenerate;
}
