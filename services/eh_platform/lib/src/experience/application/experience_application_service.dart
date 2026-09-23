import 'package:eh_platform/src/experience/application/dto/today_experience_dto.dart';
import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/ports/discoverable_story_candidate_port.dart';
import 'package:eh_platform/src/experience/application/services/adaptive_experience_composer.dart';
import 'package:eh_platform/src/experience/application/services/experience_selection_service.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/persistence/postgres_journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/transactions/transaction_boundary.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';

/// GetTodayExperience application query (J.1).
///
/// ```text
/// Authenticated principal
///   → Current Journey (existing findCurrentByUserId)
///   → Understanding inputs (behaviorPatterns)
///   → Experience Selection / HS.8 composition
///   → TodayExperienceDto
/// ```
///
/// Read-only. Does not mutate Journey or persist Today's Experience.
final class ExperienceApplicationService {
  ExperienceApplicationService({
    required this.transactions,
    required this.journeyRepository,
    required ExperienceSelectionService experienceSelectionService,
    DiscoverableStoryCandidatePort? storyCandidatePort,
    AdaptiveExperienceComposer? composer,
  })  : _storyCandidatePort =
            storyCandidatePort ?? const EmptyDiscoverableStoryCandidatePort(),
        _composer = composer ??
            AdaptiveExperienceComposer(
              reflectionSelectionService: experienceSelectionService,
            );

  final TransactionBoundary transactions;
  final JourneyRepository journeyRepository;
  final DiscoverableStoryCandidatePort _storyCandidatePort;
  final AdaptiveExperienceComposer _composer;

  Future<Result<TodayExperienceDto>> getTodayExperience({
    required UserId userId,
  }) async {
    try {
      return await transactions.run(() async {
        final journey = await _currentJourney(userId);
        if (journey == null) {
          return const Failure(
            code: 'not_found',
            message: 'No current journey',
          );
        }

        final signals = AdaptiveDiscoverySignals(
          behaviorPatterns: journey.behaviorPatterns,
        );
        final candidates = await _storyCandidatePort.findRelevant(signals);
        final selected = _composer.compose(
          journey: journey,
          signals: signals,
          candidates: candidates,
        );

        return Success(
          TodayExperienceDto.fromSelection(
            experience: selected,
            journeyId: journey.id.value,
          ),
        );
      });
    } catch (e) {
      return Failure(
        code: 'get_today_experience_failed',
        message: 'Failed to get today experience: $e',
      );
    }
  }

  /// Preserves H.2 / PF.3 current-Journey semantics: latest `updated_at`.
  Future<Journey?> _currentJourney(UserId userId) async {
    final repo = journeyRepository;
    if (repo is OwnedInMemoryJourneyRepository) {
      return repo.findCurrentByUserId(userId);
    }
    if (repo is PostgresJourneyRepository) {
      return repo.findCurrentByUserId(userId);
    }
    return null;
  }
}
