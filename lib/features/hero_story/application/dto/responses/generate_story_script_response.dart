import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

final class GenerateStoryScriptResponse {
  const GenerateStoryScriptResponse({
    required this.story,
    required this.storyId,
    required this.authoredRepresentationId,
    required this.format,
    this.idempotentReplay = false,
  });

  final Story story;
  final StoryId storyId;
  final StoryRepresentationId authoredRepresentationId;
  final StoryRepresentationFormat format;
  final bool idempotentReplay;
}
