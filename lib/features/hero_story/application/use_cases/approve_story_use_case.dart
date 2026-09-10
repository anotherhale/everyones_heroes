import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

final class ApproveStoryUseCase implements UseCase<StoryIdRequest, Story> {
  const ApproveStoryUseCase({
    required StoryRepository storyRepository,
    required EventBus eventBus,
  }) : _storyRepository = storyRepository,
       _eventBus = eventBus;

  final StoryRepository _storyRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Story>> execute(StoryIdRequest request) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      if (story.lifecycleStatus == StoryLifecycleStatus.processing) {
        story.markReadyForReview();
      }

      story.approve();
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to approve story: $e');
    }
  }
}
