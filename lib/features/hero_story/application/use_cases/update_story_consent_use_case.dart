import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

final class UpdateStoryConsentUseCase
    implements UseCase<UpdateStoryConsentRequest, Story> {
  const UpdateStoryConsentUseCase({
    required this._storyRepository,
    required this._eventBus,
  });

  final StoryRepository _storyRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Story>> execute(UpdateStoryConsentRequest request) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      final at = request.at ?? DateTime.now();
      var consent = story.consent;

      if (request.grantProcessing) {
        consent = consent.grantProcessing(at);
      }
      if (request.grantPublication) {
        consent = consent.grantPublication(at);
      }
      if (request.grantAiTransformation) {
        consent = consent.grantAiTransformation(at);
      }
      if (request.revokeProcessing) {
        consent = consent.revokeProcessing();
      }
      if (request.revokePublication) {
        consent = consent.revokePublication();
      }
      if (request.revokeAiTransformation) {
        consent = consent.revokeAiTransformation();
      }

      story.updateConsent(consent, at: at);
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to update story consent: $e');
    }
  }
}
