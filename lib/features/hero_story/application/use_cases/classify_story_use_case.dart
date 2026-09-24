import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/classify_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/services/discoverable_story_candidate_sync.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

final class ClassifyStoryUseCase
    implements UseCase<ClassifyStoryRequest, Story> {
  const ClassifyStoryUseCase({
    required StoryRepository storyRepository,
    required EventBus eventBus,
    HeroRepository? heroRepository,
    DiscoverableStoryCandidateSync? candidateSync,
  })  : _storyRepository = storyRepository,
        _eventBus = eventBus,
        _heroRepository = heroRepository,
        _candidateSync = candidateSync;

  final StoryRepository _storyRepository;
  final EventBus _eventBus;
  final HeroRepository? _heroRepository;
  final DiscoverableStoryCandidateSync? _candidateSync;

  @override
  Future<Result<Story>> execute(ClassifyStoryRequest request) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      story.classify(request.classification);
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      // Theme IDs drive ranking / eligibility — refresh when already published.
      if (story.isPublished) {
        final sync = _candidateSync;
        final heroes = _heroRepository;
        if (sync != null && heroes != null) {
          final hero = await heroes.findById(story.heroId);
          if (hero != null) {
            await sync.sync(story: story, hero: hero);
          }
        }
      }

      return Success(story);
    } catch (e) {
      return Failure('Failed to classify story: $e');
    }
  }
}
