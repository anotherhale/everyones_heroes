import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_content_suitability_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Authoritative content-suitability update path.
///
/// Does not raise a dedicated domain event in HS.2 (no current consumer).
final class UpdateStoryContentSuitabilityUseCase
    implements UseCase<UpdateStoryContentSuitabilityRequest, Story> {
  const UpdateStoryContentSuitabilityUseCase({
    required this._storyRepository,
    required this._eventBus,
  });

  final StoryRepository _storyRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Story>> execute(
    UpdateStoryContentSuitabilityRequest request,
  ) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      story.updateContentSuitability(request.contentSuitability);
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to update story content suitability: $e');
    }
  }
}
