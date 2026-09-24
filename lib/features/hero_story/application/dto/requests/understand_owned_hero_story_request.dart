import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Orchestrates explicit transcription + grounded reading (HS.12.3).
final class UnderstandOwnedHeroStoryRequest {
  const UnderstandOwnedHeroStoryRequest({
    required this.storyId,
    required this.ownerHeroId,
    this.isRetry = false,
    this.processingVersion = 'hs12.3.v1',
    this.occurredAt,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
  final bool isRetry;
  final String processingVersion;
  final DateTime? occurredAt;
}
