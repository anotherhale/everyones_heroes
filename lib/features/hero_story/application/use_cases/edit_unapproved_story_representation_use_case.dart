import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_unapproved_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Human in-place edit of an unapproved representation (HS.5 / D5).
final class EditUnapprovedStoryRepresentationUseCase
    implements UseCase<EditUnapprovedStoryRepresentationRequest, Story> {
  const EditUnapprovedStoryRepresentationUseCase({
    required this._storyRepository,
    required this._eventBus,
  });

  final StoryRepository _storyRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Story>> execute(
    EditUnapprovedStoryRepresentationRequest request,
  ) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      final narrativeBefore = story.narrative.value;
      story.replaceUnapprovedRepresentationText(
        representationId: request.representationId,
        textContent: request.textContent,
        at: request.occurredAt,
      );
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      if (story.narrative.value != narrativeBefore) {
        return const Failure(
          'Editing a representation must not mutate canonical Story narrative.',
        );
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to edit story representation: $e');
    }
  }
}
