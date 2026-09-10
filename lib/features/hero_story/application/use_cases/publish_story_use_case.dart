import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

final class PublishStoryUseCase implements UseCase<PublishStoryRequest, Story> {
  const PublishStoryUseCase({
    required this._storyRepository,
    required this._heroRepository,
    required this._eventBus,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Story>> execute(PublishStoryRequest request) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      final hero = await _heroRepository.findById(story.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${story.heroId.value}');
      }

      if (request.visibility != null) {
        story.changeVisibility(request.visibility!);
      }

      story.publish();
      hero.attachPublishedStory(story.id);

      await _storyRepository.save(story);
      await _heroRepository.save(hero);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      for (final event in hero.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to publish story: $e');
    }
  }
}
