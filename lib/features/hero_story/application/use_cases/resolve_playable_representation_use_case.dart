import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/resolve_playable_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/playable_representation.dart';
import 'package:everyonesheroes/features/hero_story/application/experience/playable_representation_selector.dart';
import 'package:everyonesheroes/features/hero_story/application/experience/story_experience_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_discoverability_policy.dart';

/// Resolves an authoritative playable representation with D3 priority rules.
final class ResolvePlayableRepresentationUseCase
    implements
        UseCase<ResolvePlayableRepresentationRequest, PlayableRepresentation> {
  const ResolvePlayableRepresentationUseCase({
    required this._storyRepository,
    required this._heroRepository,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;

  @override
  Future<Result<PlayableRepresentation>> execute(
    ResolvePlayableRepresentationRequest request,
  ) async {
    try {
      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      if (!StoryDiscoverabilityPolicy.isDiscoverable(story)) {
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

      if (request.representationId != null) {
        final explicit = story.findRepresentation(request.representationId!);
        if (explicit == null || !explicit.isAuthoritative) {
          return Failure(
            'Representation is not authoritative: '
            '${request.representationId!.value}',
          );
        }
        return Success(StoryExperienceMapper.toPlayable(explicit));
      }

      final selected = PlayableRepresentationSelector.select(
        candidates: story.representations,
        originalLanguage: story.originalLanguage,
        preferredLanguage: request.preferredLanguage,
      );

      if (selected == null) {
        return Failure(
          'No authoritative representation available for story: '
          '${request.storyId.value}',
        );
      }

      return Success(StoryExperienceMapper.toPlayable(selected));
    } catch (e) {
      return Failure('Failed to resolve playable representation: $e');
    }
  }
}
