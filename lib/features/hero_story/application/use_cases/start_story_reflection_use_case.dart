import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_reflection_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

/// Explicit user-initiated reflection after Story consumption (HS.7 D11).
///
/// Reuses the existing H.2 [CreateReflectionUseCase]. Never invoked
/// automatically by begin/consume paths.
final class StartStoryReflectionUseCase
    implements UseCase<StartStoryReflectionRequest, Reflection> {
  const StartStoryReflectionUseCase({
    required this._getStoryExperienceUseCase,
    required this._createReflectionUseCase,
  });

  final GetStoryExperienceUseCase _getStoryExperienceUseCase;
  final CreateReflectionUseCase _createReflectionUseCase;

  @override
  Future<Result<Reflection>> execute(
    StartStoryReflectionRequest request,
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

      // Prove discoverability before creating reflection; story title stays
      // presentation-only context (no Story foreign key on Reflection).
      if ((experienceResult as Success<StoryExperienceDetail>)
          .value
          .title
          .isEmpty) {
        return const Failure('Story experience is missing a title.');
      }

      return await _createReflectionUseCase.execute(
        CreateReflectionRequest(
          reflectionId: request.reflectionId ?? ReflectionId.generate(),
          journeyId: request.journeyId,
        ),
      );
    } catch (e) {
      return Failure('Failed to start story reflection: $e');
    }
  }
}
