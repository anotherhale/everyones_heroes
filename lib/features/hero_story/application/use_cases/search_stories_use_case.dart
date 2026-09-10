import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_search_port.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';

final class SearchStoriesUseCase
    implements UseCase<StorySearchQuery, List<StoryId>> {
  const SearchStoriesUseCase({required StorySearchPort storySearchPort})
    : _storySearchPort = storySearchPort;

  final StorySearchPort _storySearchPort;

  @override
  Future<Result<List<StoryId>>> execute(StorySearchQuery request) async {
    try {
      final ids = await _storySearchPort.search(request);
      return Success(ids);
    } catch (e) {
      return Failure('Failed to search stories: $e');
    }
  }
}
