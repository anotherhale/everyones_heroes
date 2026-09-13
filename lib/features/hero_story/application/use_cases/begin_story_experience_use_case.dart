import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/begin_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/resolve_playable_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/playable_representation.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_consumption_session.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/resolve_playable_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';

/// Begins Story consumption without creating a Reflection (HS.7 Story Begin).
///
/// Intentionally independent from Life Journey `BeginExperienceUseCase`, which
/// always creates a Reflection. This path:
/// - establishes a consumption session over a discoverable Story
/// - does not create Reflection
/// - does not create BehavioralEvidence
/// - does not modify Life Journey / Mission state
/// - does not publish domain events
final class BeginStoryExperienceUseCase
    implements
        UseCase<BeginStoryExperienceRequest, StoryConsumptionSession> {
  const BeginStoryExperienceUseCase({
    required this._getStoryExperienceUseCase,
    required this._resolvePlayableRepresentationUseCase,
  });

  final GetStoryExperienceUseCase _getStoryExperienceUseCase;
  final ResolvePlayableRepresentationUseCase
  _resolvePlayableRepresentationUseCase;

  @override
  Future<Result<StoryConsumptionSession>> execute(
    BeginStoryExperienceRequest request,
  ) async {
    try {
      final experienceResult = await _getStoryExperienceUseCase.execute(
        GetStoryExperienceRequest(
          storyId: request.storyId,
          preferredLanguage: request.preferredLanguage,
        ),
      );

      if (experienceResult.isFailure) {
        return Failure((experienceResult as Failure<StoryExperienceDetail>).error);
      }

      final detail =
          (experienceResult as Success<StoryExperienceDetail>).value;

      final resolveResult = await _resolvePlayableRepresentationUseCase.execute(
        ResolvePlayableRepresentationRequest(
          storyId: request.storyId,
          preferredLanguage: request.preferredLanguage,
          representationId: request.representationId,
        ),
      );

      if (resolveResult.isFailure) {
        return Failure(
          (resolveResult as Failure<PlayableRepresentation>).error,
        );
      }

      final playable =
          (resolveResult as Success<PlayableRepresentation>).value;

      return Success(
        StoryConsumptionSession(
          storyId: request.storyId,
          experience: detail,
          selectedRepresentation: playable,
          startedAt:
              request.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    } catch (e) {
      return Failure('Failed to begin story experience: $e');
    }
  }
}
