import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/services/deterministic_experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/journey_repository.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart';

void main() {
  group('DefaultGetTodayExperienceUseCase', () {
    late JourneyRepository journeyRepository;
    late CurrentJourneyContext currentJourneyContext;
    late DefaultGetTodayExperienceUseCase useCase;

    setUp(() {
      journeyRepository = InMemoryJourneyRepository();
      currentJourneyContext = DefaultCurrentJourneyContext();

      useCase = DefaultGetTodayExperienceUseCase(
        journeyRepository: journeyRepository,
        currentJourneyContext: currentJourneyContext,
        experienceSelectionService:
            const DeterministicExperienceSelectionService(),
      );
    });

    test('returns the selected experience for the current journey', () async {
      final journey = Journey.create(
        id: JourneyId.generate(),
        vision: JourneyVision('Become the person I want to be.'),
      );

      await journeyRepository.save(journey);
      currentJourneyContext.setCurrentJourney(journey.id);

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);

      result.fold(
        onSuccess: (experience) {
          expect(experience.id, 'default-reflection');
          expect(experience.type, ExperienceType.reflection);
        },
        onFailure: fail,
      );
    });

    test('fails when there is no current journey', () async {
      final result = await useCase.execute();

      expect(result.isFailure, isTrue);

      result.fold(
        onSuccess: (_) => fail('Expected failure'),
        onFailure: (error) {
          expect(error, 'No current journey is available.');
        },
      );
    });

    test('fails when the current journey cannot be found', () async {
      final journeyId = JourneyId.generate();

      currentJourneyContext.setCurrentJourney(journeyId);

      final result = await useCase.execute();

      expect(result.isFailure, isTrue);

      result.fold(
        onSuccess: (_) => fail('Expected failure'),
        onFailure: (error) {
          expect(error, 'Journey not found: ${journeyId.value}');
        },
      );
    });
  });
}
