import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

final class TranscribeStoryResponse {
  const TranscribeStoryResponse({
    required this.story,
    required this.storyId,
    required this.transcriptRepresentationId,
    required this.mediaReference,
    this.idempotentReplay = false,
  });

  final Story story;
  final StoryId storyId;
  final StoryRepresentationId transcriptRepresentationId;
  final MediaReference? mediaReference;
  final bool idempotentReplay;
}
