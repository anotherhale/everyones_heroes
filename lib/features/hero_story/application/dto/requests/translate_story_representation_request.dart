import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';

final class TranslateStoryRepresentationRequestDto {
  const TranslateStoryRepresentationRequestDto({
    required this.storyId,
    required this.sourceRepresentationId,
    required this.translatedRepresentationId,
    required this.targetLanguage,
    required this.requestId,
    this.processingVersion = 'hs5-v1',
    this.occurredAt,
  });

  final StoryId storyId;
  final StoryRepresentationId sourceRepresentationId;
  final StoryRepresentationId translatedRepresentationId;
  final LanguageCode targetLanguage;
  final String requestId;
  final String processingVersion;
  final DateTime? occurredAt;
}
