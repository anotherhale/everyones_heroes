import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/consume_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_consumption_session.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/experience/story_experience_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_discoverability_policy.dart';

/// Completes Story consumption without BehavioralEvidence (HS.7 D9).
///
/// Verifies discoverability and authoritative representation, then returns a
/// completed ephemeral session. Does not:
/// - raise domain events
/// - create BehavioralEvidence or BehaviorPatterns
/// - alter Mission / Life Journey progress
/// - create Reflection
final class ConsumeStoryExperienceUseCase
    implements
        UseCase<ConsumeStoryExperienceRequest, StoryConsumptionSession> {
  const ConsumeStoryExperienceUseCase({
    required this._getStoryExperienceUseCase,
    required this._storyRepository,
    required this._heroRepository,
  });

  final GetStoryExperienceUseCase _getStoryExperienceUseCase;
  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;

  @override
  Future<Result<StoryConsumptionSession>> execute(
    ConsumeStoryExperienceRequest request,
  ) async {
    try {
      final experienceResult = await _getStoryExperienceUseCase.execute(
        GetStoryExperienceRequest(storyId: request.storyId),
      );

      if (experienceResult.isFailure) {
        return Failure(
          (experienceResult as Failure<StoryExperienceDetail>).error,
        );
      }

      final detail =
          (experienceResult as Success<StoryExperienceDetail>).value;

      final story = await _storyRepository.findById(request.storyId);
      if (story == null ||
          !StoryDiscoverabilityPolicy.isDiscoverable(story)) {
        return Failure(
          'Story is not discoverable: ${request.storyId.value}',
        );
      }

      final hero = await _heroRepository.findById(story.heroId);
      if (hero == null || !HeroDiscoverabilityPolicy.isDiscoverable(hero)) {
        return Failure(
          'Story is not discoverable: ${request.storyId.value}',
        );
      }

      final representation = story.findRepresentation(request.representationId);
      if (representation == null || !representation.isAuthoritative) {
        return Failure(
          'Representation is not authoritative: '
          '${request.representationId.value}',
        );
      }

      return Success(
        StoryConsumptionSession(
          storyId: request.storyId,
          experience: detail,
          selectedRepresentation:
              StoryExperienceMapper.toPlayable(representation),
          startedAt: DateTime.fromMillisecondsSinceEpoch(0),
          completed: true,
        ),
      );
    } catch (e) {
      return Failure('Failed to consume story experience: $e');
    }
  }
}
