import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';

/// Request to generate a grounded captured-story reading (HS.12.3).
final class GenerateCapturedStoryReadingAppRequest {
  const GenerateCapturedStoryReadingAppRequest({
    required this.storyId,
    required this.ownerHeroId,
    required this.transcriptRepresentationId,
    required this.transcriptText,
    this.processingVersion = 'hs12.3.v1',
    this.occurredAt,
    this.forceRegenerate = false,
  });

  final StoryId storyId;
  final HeroId ownerHeroId;
  final StoryRepresentationId transcriptRepresentationId;
  final String transcriptText;
  final String processingVersion;
  final DateTime? occurredAt;
  final bool forceRegenerate;
}
