import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/services/discoverable_story_candidate_sync.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

final class PublishStoryUseCase implements UseCase<PublishStoryRequest, Story> {
  const PublishStoryUseCase({
    required StoryRepository storyRepository,
    required HeroRepository heroRepository,
    required EventBus eventBus,
    DiscoverableStoryCandidateSync? candidateSync,
  })  : _storyRepository = storyRepository,
        _heroRepository = heroRepository,
        _eventBus = eventBus,
        _candidateSync = candidateSync;

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final EventBus _eventBus;

  /// Optional J.2 Slice 5 projection sync. Soft-fail only — never rolls back
  /// publish. Null / no-op when platform authority is not configured.
  final DiscoverableStoryCandidateSync? _candidateSync;

  @override
  Future<Result<Story>> execute(PublishStoryRequest request) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      // Referential integrity only: do not mutate Hero for publication.
      final hero = await _heroRepository.findById(story.heroId);
      if (hero == null) {
        return Failure('Hero not found: ${story.heroId.value}');
      }

      if (request.visibility != null) {
        story.changeVisibility(request.visibility!);
      }

      story.publish();
      await _storyRepository.save(story);

      for (final event in story.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      // Derived discovery projection — after durable Story authority.
      await _candidateSync?.sync(story: story, hero: hero);

      return Success(story);
    } catch (e) {
      return Failure('Failed to publish story: $e');
    }
  }
}
