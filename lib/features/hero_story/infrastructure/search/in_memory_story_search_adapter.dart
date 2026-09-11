import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_search_port.dart';

/// Deterministic catalog search. Does not personalize.
final class InMemoryStorySearchAdapter implements StorySearchPort {
  InMemoryStorySearchAdapter(this._storyRepository);

  final StoryRepository _storyRepository;

  @override
  Future<List<StoryId>> search(StorySearchQuery query) async {
    final stories = await _storyRepository.findAll();

    return stories
        .where((story) {
          if (query.publishedOnly &&
              story.lifecycleStatus != StoryLifecycleStatus.published) {
            return false;
          }

          if (query.heroId != null && story.heroId != query.heroId) {
            return false;
          }

          if (query.originalLanguage != null &&
              story.originalLanguage != query.originalLanguage) {
            return false;
          }

          if (query.availableLanguage != null) {
            final languages = {
              story.originalLanguage,
              ...story.availableLanguages,
            };
            if (!languages.contains(query.availableLanguage)) {
              return false;
            }
          }

          if (query.subjects.isNotEmpty &&
              !query.subjects.any(story.classification.subjects.contains)) {
            return false;
          }

          if (query.challenges.isNotEmpty &&
              !query.challenges.any(story.classification.challenges.contains)) {
            return false;
          }

          if (query.narrativeThemeIds.isNotEmpty &&
              !query.narrativeThemeIds.any(
                story.classification.narrativeThemeIds.contains,
              )) {
            return false;
          }

          if (query.audience != null &&
              story.classification.audience != query.audience) {
            return false;
          }

          if (query.maxProfanity != null &&
              story.contentSuitability.profanity.index >
                  query.maxProfanity!.index) {
            return false;
          }

          if (query.text != null && query.text!.trim().isNotEmpty) {
            final needle = query.text!.trim().toLowerCase();
            final haystack =
                '${story.title.value} ${story.narrative.value}'.toLowerCase();
            if (!haystack.contains(needle)) {
              return false;
            }
          }

          return true;
        })
        .map((story) => story.id)
        .toList(growable: false);
  }
}
