import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Revoke Story-level voice cloning authorization / denial back to not-granted
/// (HS.12.10).
final class RevokeStoryVoiceCloningRequest {
  const RevokeStoryVoiceCloningRequest({
    required this.storyId,
    required this.ownerHeroId,
    this.at,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
  final DateTime? at;
}
