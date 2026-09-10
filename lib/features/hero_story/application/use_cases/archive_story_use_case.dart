import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

final class ArchiveStoryUseCase implements UseCase<StoryIdRequest, Story> {
  const ArchiveStoryUseCase({
    required StoryRepository storyRepository,
    required HeroRepository heroRepository,
    required EventBus eventBus,
  }) : _storyRepository = storyRepository,
       _heroRepository = heroRepository,
       _eventBus = eventBus;

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Story>> execute(StoryIdRequest request) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      story.archive();

      final hero = await _heroRepository.findById(story.heroId);
      if (hero != null) {
        hero.detachPublishedStory(story.id);
        await _heroRepository.save(hero);
      }

      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to archive story: $e');
    }
  }
}
