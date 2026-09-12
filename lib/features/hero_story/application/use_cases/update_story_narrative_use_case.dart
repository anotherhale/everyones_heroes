import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_narrative_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Human-only canonical narrative authorship (HS.5 / D3).
///
/// Never invokes AI ports. Representation approval does not call this use case.
final class UpdateStoryNarrativeUseCase
    implements UseCase<UpdateStoryNarrativeRequest, Story> {
  const UpdateStoryNarrativeUseCase({
    required this._storyRepository,
    required this._eventBus,
  });

  final StoryRepository _storyRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Story>> execute(UpdateStoryNarrativeRequest request) async {
    try {
      if (request.title == null && request.narrative == null) {
        return const Failure(
          'UpdateStoryNarrative requires a title and/or narrative.',
        );
      }

      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      story.updateNarrative(
        title: request.title,
        narrative: request.narrative,
      );
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to update story narrative: $e');
    }
  }
}
