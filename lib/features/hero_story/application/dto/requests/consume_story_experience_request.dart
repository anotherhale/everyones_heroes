import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

/// Completes Story consumption locally — no BehavioralEvidence (HS.7 D9).
final class ConsumeStoryExperienceRequest {
  const ConsumeStoryExperienceRequest({
    required this.storyId,
    required this.representationId,
  });

  final StoryId storyId;
  final StoryRepresentationId representationId;
}
