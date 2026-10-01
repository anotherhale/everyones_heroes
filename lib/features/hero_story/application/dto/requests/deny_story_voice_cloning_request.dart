import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Explicitly deny Story-level voice cloning (HS.12.10).
///
/// Denial always wins over profile-level cloning authorization under
/// perProfile scope.
final class DenyStoryVoiceCloningRequest {
  const DenyStoryVoiceCloningRequest({
    required this.storyId,
    required this.ownerHeroId,
    this.at,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
  final DateTime? at;
}
