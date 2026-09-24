import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';

/// Combined result of explicit understand-my-story (HS.12.3).
final class UnderstandOwnedHeroStoryResponse {
  const UnderstandOwnedHeroStoryResponse({
    required this.storyId,
    required this.transcriptRepresentationId,
    required this.transcriptText,
    required this.reading,
    this.transcriptionIdempotentReplay = false,
    this.readingIdempotentReplay = false,
  });

  final StoryId storyId;
  final StoryRepresentationId transcriptRepresentationId;
  final String transcriptText;
  final CapturedStoryReading reading;
  final bool transcriptionIdempotentReplay;
  final bool readingIdempotentReplay;
}
