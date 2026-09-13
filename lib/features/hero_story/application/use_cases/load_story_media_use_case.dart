import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';

/// Retrieves media bytes only for discoverable Stories + authoritative reps.
///
/// Reuses [StoryMediaStoragePort]. Does not create playback aggregates or
/// BehavioralEvidence.
final class LoadStoryMediaUseCase
    implements UseCase<LoadStoryMediaRequest, StoryMediaBytes> {
  const LoadStoryMediaUseCase({
    required this._storyRepository,
    required this._heroRepository,
    required this._mediaStorage,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final StoryMediaStoragePort _mediaStorage;

  @override
  Future<Result<StoryMediaBytes>> execute(LoadStoryMediaRequest request) async {
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

      final representation = story.findRepresentation(request.representationId);
      if (representation == null || !representation.isAuthoritative) {
        return Failure(
          'Representation is not authoritative: '
          '${request.representationId.value}',
        );
      }

      final mediaReference = representation.mediaReference;
      if (mediaReference == null) {
        return Failure(
          'Representation has no media: ${request.representationId.value}',
        );
      }

      final bytes = await _mediaStorage.retrieve(mediaReference);
      if (bytes == null) {
        return Failure(
          'Media not found for representation: '
          '${request.representationId.value}',
        );
      }

      return Success(
        StoryMediaBytes(
          storyId: story.id,
          representationId: representation.id,
          format: representation.format,
          bytes: bytes,
        ),
      );
    } catch (e) {
      return Failure('Failed to load story media: $e');
    }
  }
}
