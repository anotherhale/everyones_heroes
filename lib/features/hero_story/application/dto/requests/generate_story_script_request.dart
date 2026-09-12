import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';

final class GenerateStoryScriptRequest {
  const GenerateStoryScriptRequest({
    required this.storyId,
    required this.sourceRepresentationId,
    required this.authoredRepresentationId,
    required this.requestId,
    this.understandingId,
    this.targetFormat = StoryRepresentationFormat.script,
    this.processingVersion = 'hs5-v1',
    this.occurredAt,
  });

  final StoryId storyId;
  final StoryRepresentationId sourceRepresentationId;
  final StoryRepresentationId authoredRepresentationId;
  final String requestId;
  final StoryUnderstandingId? understandingId;
  final StoryRepresentationFormat targetFormat;
  final String processingVersion;
  final DateTime? occurredAt;
}
