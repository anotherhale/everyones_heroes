import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';

/// Request for discoverability-gated Story experience detail (HS.7).
final class GetStoryExperienceRequest {
  const GetStoryExperienceRequest({
    required this.storyId,
    this.preferredLanguage,
  });

  final StoryId storyId;
  final LanguageCode? preferredLanguage;
}
