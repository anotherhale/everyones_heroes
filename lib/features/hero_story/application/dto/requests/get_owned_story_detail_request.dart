import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Owner-scoped Story detail request (HS.10).
final class GetOwnedStoryDetailRequest {
  const GetOwnedStoryDetailRequest({
    required this.storyId,
    required this.ownerHeroId,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
}
