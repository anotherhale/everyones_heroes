import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_owned_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';

/// Loads original/owned Story media without Discoverability gates (HS.10).
///
/// Ownership is required. Discoverability-gated [LoadStoryMediaUseCase] remains
/// unchanged for seeker playback.
final class LoadOwnedStoryMediaUseCase
    implements UseCase<LoadOwnedStoryMediaRequest, StoryMediaBytes> {
  const LoadOwnedStoryMediaUseCase({
    required this._storyRepository,
    required this._heroRepository,
    required this._mediaStorage,
  });

  final StoryRepository _storyRepository;
  final HeroRepository _heroRepository;
  final StoryMediaStoragePort _mediaStorage;

  @override
  Future<Result<StoryMediaBytes>> execute(
    LoadOwnedStoryMediaRequest request,
  ) async {
    try {
      final hero = await _heroRepository.findById(request.ownerHeroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.ownerHeroId.value}');
      }

      final story = await _storyRepository.findById(request.storyId);
      if (story == null) {
        return Failure('Story not found: ${request.storyId.value}');
      }

      if (story.heroId != request.ownerHeroId) {
        return Failure(
          'Story is not owned by hero: ${request.storyId.value}',
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
      return Failure('Failed to load owned story media: $e');
    }
  }
}
