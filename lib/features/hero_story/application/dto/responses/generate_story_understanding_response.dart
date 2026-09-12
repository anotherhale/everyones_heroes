import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_understanding.dart';

final class GenerateStoryUnderstandingResponse {
  const GenerateStoryUnderstandingResponse({
    required this.understanding,
    required this.understandingId,
    required this.storyId,
    this.supersededUnderstandingId,
    this.idempotentReplay = false,
  });

  final StoryUnderstanding understanding;
  final StoryUnderstandingId understandingId;
  final StoryId storyId;
  final StoryUnderstandingId? supersededUnderstandingId;
  final bool idempotentReplay;
}
