import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';

/// Authorize Story-level voice cloning (HS.12.10).
///
/// Independent of synthetic narration ([voiceRenderingApprovedAt]).
final class AuthorizeStoryVoiceCloningRequest {
  const AuthorizeStoryVoiceCloningRequest({
    required this.storyId,
    required this.ownerHeroId,
    this.at,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
  final DateTime? at;
}
