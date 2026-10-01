import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/deny_story_voice_cloning_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

/// Explicitly denies Story-level voice cloning (HS.12.10).
///
/// Denial always wins over profile-level cloning authorization.
final class DenyStoryVoiceCloningUseCase
    implements UseCase<DenyStoryVoiceCloningRequest, Story> {
  const DenyStoryVoiceCloningUseCase({
    required StoryRepository storyRepository,
    required EventBus eventBus,
  })  : _storyRepository = storyRepository,
        _eventBus = eventBus;

  final StoryRepository _storyRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Story>> execute(
    DenyStoryVoiceCloningRequest request,
  ) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }
      if (story.heroId != request.ownerHeroId) {
        return Failure(
          'Not authorized to modify Story ${request.storyId.value} for hero '
          '${request.ownerHeroId.value}.',
        );
      }

      final at = request.at ?? DateTime.now();
      story.updateConsent(story.consent.denyVoiceCloning(at), at: at);
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to deny story voice cloning: $e');
    }
  }
}
