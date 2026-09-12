import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';

final class TranslateStoryRepresentationResponse {
  const TranslateStoryRepresentationResponse({
    required this.story,
    required this.storyId,
    required this.translatedRepresentationId,
    required this.targetLanguage,
    this.idempotentReplay = false,
  });

  final Story story;
  final StoryId storyId;
  final StoryRepresentationId translatedRepresentationId;
  final LanguageCode targetLanguage;
  final bool idempotentReplay;
}
