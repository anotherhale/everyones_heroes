import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

final class GetOwnedStoryTranscriptionStatusRequest {
  const GetOwnedStoryTranscriptionStatusRequest({
    required this.storyId,
    required this.ownerHeroId,
    this.sourceRepresentationId,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
  final StoryRepresentationId? sourceRepresentationId;
}
