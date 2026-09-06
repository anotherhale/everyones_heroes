import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

abstract interface class BeginExperienceUseCase {
  Future<Result<Reflection>> execute({required ExperienceAction action});
}

final class DefaultBeginExperienceUseCase implements BeginExperienceUseCase {
  const DefaultBeginExperienceUseCase({
    required this.currentJourneyContext,
    required this.createReflectionUseCase,
  });

  final CurrentJourneyContext currentJourneyContext;
  final UseCase<CreateReflectionRequest, Reflection> createReflectionUseCase;

  @override
  Future<Result<Reflection>> execute({required ExperienceAction action}) async {
    if (action != ExperienceAction.begin) {
      return const Failure('Unsupported experience action.');
    }

    final journeyId = currentJourneyContext.currentJourneyId;

    if (journeyId == null) {
      return const Failure('No current journey is available.');
    }

    return createReflectionUseCase.execute(
      CreateReflectionRequest(
        reflectionId: ReflectionId.generate(),
        journeyId: journeyId,
      ),
    );
  }
}
