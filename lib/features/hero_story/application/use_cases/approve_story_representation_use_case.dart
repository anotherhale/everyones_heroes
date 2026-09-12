import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/authoring/approval_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/approve_story_representation_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Explicit Hero approval of an AI-derived StoryRepresentation (HS.5 / D6).
///
/// Does not promote content into Story.narrative (D3).
final class ApproveStoryRepresentationUseCase
    implements
        UseCase<
          ApproveStoryRepresentationRequest,
          ApproveStoryRepresentationResponse
        > {
  ApproveStoryRepresentationUseCase({
    required this._storyRepository,
    required this._eventBus,
    ApprovalCompletionStore? completionStore,
  }) : _completionStore = completionStore ?? InMemoryApprovalCompletionStore();

  final StoryRepository _storyRepository;
  final EventBus _eventBus;
  final ApprovalCompletionStore _completionStore;

  @override
  Future<Result<ApproveStoryRepresentationResponse>> execute(
    ApproveStoryRepresentationRequest request,
  ) async {
    try {
      final requestId = request.requestId?.trim();
      if (requestId != null && requestId.isNotEmpty) {
        final existing = _completionStore.find(requestId);
        if (existing != null) {
          return Success(
            ApproveStoryRepresentationResponse(
              story: existing.story,
              storyId: existing.storyId,
              representationId: existing.representationId,
              idempotentReplay: true,
            ),
          );
        }
      }

      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      final representation =
          story.findRepresentation(request.representationId);
      if (representation == null) {
        return Failure(
          'Representation not found: ${request.representationId.value}',
        );
      }

      final narrativeBefore = story.narrative.value;
      final alreadyApproved =
          representation.isAiGenerated && representation.isApproved;

      if (!alreadyApproved) {
        story.approveRepresentation(request.representationId);
        await _storyRepository.save(story);

        for (final event in story.pullDomainEvents()) {
          await _eventBus.publish(event);
        }
      }

      if (story.narrative.value != narrativeBefore) {
        return const Failure(
          'Representation approval must not mutate canonical Story narrative.',
        );
      }

      final response = ApproveStoryRepresentationResponse(
        story: story,
        storyId: story.id,
        representationId: request.representationId,
        idempotentReplay: alreadyApproved,
      );

      if (requestId != null && requestId.isNotEmpty) {
        _completionStore.save(requestId, response);
      }

      return Success(response);
    } catch (e) {
      return Failure('Failed to approve story representation: $e');
    }
  }
}
