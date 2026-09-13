import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/discoverable_story_candidate_port.dart';
import 'package:everyonesheroes/features/life_journey/application/services/adaptive_experience_composer.dart';
import 'package:everyonesheroes/features/life_journey/application/services/experience_selection_service.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/journey_repository.dart';

abstract interface class GetTodayExperienceUseCase {
  Future<Result<AdaptiveExperience>> execute();
}

/// UI.3 Today’s Experience orchestration with HS.8 adaptive Story relevance.
///
/// Flow:
/// Journey → AdaptiveDiscoverySignals → Discover* candidates → compose
/// → AdaptiveExperience (story or reflection fallback).
final class DefaultGetTodayExperienceUseCase
    implements GetTodayExperienceUseCase {
  DefaultGetTodayExperienceUseCase({
    required JourneyRepository journeyRepository,
    required CurrentJourneyContext currentJourneyContext,
    required ExperienceSelectionService experienceSelectionService,
    ResolveAdaptiveDiscoverySignalsUseCase? resolveAdaptiveDiscoverySignals,
    DiscoverableStoryCandidatePort? storyCandidatePort,
    AdaptiveExperienceComposer? composer,
  }) : _journeyRepository = journeyRepository,
       _currentJourneyContext = currentJourneyContext,
       _resolveAdaptiveDiscoverySignals = resolveAdaptiveDiscoverySignals,
       _storyCandidatePort =
           storyCandidatePort ?? const EmptyDiscoverableStoryCandidatePort(),
       _composer =
           composer ??
           AdaptiveExperienceComposer(
             reflectionSelectionService: experienceSelectionService,
           ),
       _experienceSelectionService = experienceSelectionService;

  final JourneyRepository _journeyRepository;
  final CurrentJourneyContext _currentJourneyContext;
  final ResolveAdaptiveDiscoverySignalsUseCase?
  _resolveAdaptiveDiscoverySignals;
  final DiscoverableStoryCandidatePort _storyCandidatePort;
  final AdaptiveExperienceComposer _composer;
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

      // HS.8 path when signal resolution is wired; otherwise UI.3 reflection.
      final resolveSignals = _resolveAdaptiveDiscoverySignals;
      if (resolveSignals == null) {
        final experience = _experienceSelectionService.selectFor(journey);
        return Success(experience);
      }

      final signals = await resolveSignals.execute(journey);
      final candidates = await _storyCandidatePort.findRelevant(signals);
      final experience = _composer.compose(
        journey: journey,
        signals: signals,
        candidates: candidates,
      );

      return Success(experience);
    } catch (e) {
      return Failure('Failed to get today experience: $e');
    }
  }
}
