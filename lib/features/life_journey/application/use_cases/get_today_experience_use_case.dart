import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/services/experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/journey_repository.dart';

abstract interface class GetTodayExperienceUseCase {
  Future<Result<AdaptiveExperience>> execute();
}

final class DefaultGetTodayExperienceUseCase
    implements GetTodayExperienceUseCase {
  const DefaultGetTodayExperienceUseCase({
    required this._journeyRepository,
    required this._currentJourneyContext,
    required this._experienceSelectionService,
  });

  final JourneyRepository _journeyRepository;
  final CurrentJourneyContext _currentJourneyContext;
  final ExperienceSelectionService _experienceSelectionService;

  @override
  Future<Result<AdaptiveExperience>> execute() async {
    try {
      final journeyId = _currentJourneyContext.currentJourneyId;

      if (journeyId == null) {
        return const Failure('No current journey is available.');
      }

      final journey = await _journeyRepository.findById(journeyId);

      if (journey == null) {
        return Failure('Journey not found: ${journeyId.value}');
      }

      final experience = _experienceSelectionService.selectFor(journey);

      return Success(experience);
    } catch (e) {
      return Failure('Failed to get today experience: $e');
    }
  }
}
