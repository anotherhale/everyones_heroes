import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

/// Loads media for an owned Story representation (not discoverability-gated).
final class LoadOwnedStoryMediaRequest {
  const LoadOwnedStoryMediaRequest({
    required this.storyId,
    required this.representationId,
    required this.ownerHeroId,
  });

  final StoryId storyId;
  final StoryRepresentationId representationId;
  final HeroId ownerHeroId;
}
