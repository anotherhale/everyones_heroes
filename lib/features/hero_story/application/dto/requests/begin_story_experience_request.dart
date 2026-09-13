import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';

/// Begins Story consumption without creating a Reflection (HS.7 D9 / Story Begin).
final class BeginStoryExperienceRequest {
  const BeginStoryExperienceRequest({
    required this.storyId,
    this.preferredLanguage,
    this.representationId,
    this.startedAt,
  });

  final StoryId storyId;
  final LanguageCode? preferredLanguage;
  final StoryRepresentationId? representationId;
  final DateTime? startedAt;
}
