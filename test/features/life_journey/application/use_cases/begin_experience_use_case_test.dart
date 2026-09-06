import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/begin_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';

void main() {
  group('DefaultBeginExperienceUseCase', () {
    late DefaultCurrentJourneyContext currentJourneyContext;
    late FakeCreateReflectionUseCase createReflectionUseCase;
    late DefaultBeginExperienceUseCase useCase;

    setUp(() {
      currentJourneyContext = DefaultCurrentJourneyContext();
      createReflectionUseCase = FakeCreateReflectionUseCase();

      useCase = DefaultBeginExperienceUseCase(
        currentJourneyContext: currentJourneyContext,
        createReflectionUseCase: createReflectionUseCase,
      );
    });

    test('returns failure when there is no current journey', () async {
      final result = await useCase.execute(action: ExperienceAction.begin);

      expect(result.isFailure, isTrue);
      expect(
        result.fold(onSuccess: (_) => null, onFailure: (error) => error),
        'No current journey is available.',
      );
      expect(createReflectionUseCase.lastRequest, isNull);
    });

    test('creates a reflection for the current journey', () async {
      final journeyId = JourneyId.generate();

      currentJourneyContext.setCurrentJourney(journeyId);

      final result = await useCase.execute(action: ExperienceAction.begin);

      expect(result.isSuccess, isTrue);
      expect(createReflectionUseCase.lastRequest, isNotNull);
      expect(createReflectionUseCase.lastRequest!.journeyId, journeyId);
      expect(createReflectionUseCase.lastRequest!.reflectionId, isNotNull);
    });
  });
}

final class FakeCreateReflectionUseCase
    implements UseCase<CreateReflectionRequest, Reflection> {
  CreateReflectionRequest? lastRequest;

  @override
  Future<Result<Reflection>> execute(CreateReflectionRequest request) async {
    lastRequest = request;

    return Success(
      Reflection.create(
        id: request.reflectionId,
        journeyId: request.journeyId,
        questId: request.questId,
        missionId: request.missionId,
      ),
    );
  }
}
