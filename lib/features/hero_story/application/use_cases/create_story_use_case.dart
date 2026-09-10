import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

final class CreateStoryUseCase implements UseCase<CreateStoryRequest, Story> {
  const CreateStoryUseCase({
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
  Future<Result<Story>> execute(CreateStoryRequest request) async {
    try {
      final hero = await _heroRepository.findById(request.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.heroId.value}');
      }

      if (!hero.isActive) {
        return const Failure('Cannot create a story for an archived hero.');
      }

      final story = Story.create(
        id: request.storyId,
        heroId: request.heroId,
        title: request.title,
        narrative: request.narrative,
        originalLanguage: request.originalLanguage,
        visibility: request.visibility,
        originalSourceDescription: request.originalSourceDescription,
      );

      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to create story: $e');
    }
  }
}
