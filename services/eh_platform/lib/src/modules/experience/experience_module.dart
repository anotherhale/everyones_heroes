import 'package:eh_platform/src/api/experience_api.dart';
import 'package:eh_platform/src/experience/application/experience_application_service.dart';
import 'package:eh_platform/src/experience/application/ports/discoverable_story_candidate_port.dart';
import 'package:eh_platform/src/experience/application/services/deterministic_experience_selection_service.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/transactions/transaction_boundary.dart';
import 'package:shelf/shelf.dart';

export 'package:eh_platform/src/experience/application/experience_application_service.dart';
export 'package:eh_platform/src/api/experience_api.dart';
export 'package:eh_platform/src/experience/application/ports/discoverable_story_candidate_port.dart';
export 'package:eh_platform/src/experience/application/services/deterministic_experience_selection_service.dart';
export 'package:eh_platform/src/experience/application/services/adaptive_experience_composer.dart';
export 'package:eh_platform/src/experience/application/dto/today_experience_dto.dart';

/// Experience module boundary (PF-ADR-002 / PF-ADR-013).
///
/// Owns: Experience Selection, Today's Experience composition, explainability
/// payloads. Depends on Life Journey Journey repository for current Journey +
/// understanding inputs (behaviorPatterns). Does not own H.2 detection.
///
/// HS.8 Story composition seam is preserved via
/// [DiscoverableStoryCandidatePort] (defaults empty — transitional).
final class ExperienceModule {
  const ExperienceModule();

  static const String name = 'experience';
  static const String personalizationSubmodule = 'personalization';

  /// Compose Experience Selection against an existing Life Journey repository.
  static ExperienceComponents compose({
    required TransactionBoundary transactions,
    required JourneyRepository journeyRepository,
    DiscoverableStoryCandidatePort? storyCandidatePort,
  }) {
    const selection = DeterministicExperienceSelectionService();
    final application = ExperienceApplicationService(
      transactions: transactions,
      journeyRepository: journeyRepository,
      experienceSelectionService: selection,
      storyCandidatePort:
          storyCandidatePort ?? const EmptyDiscoverableStoryCandidatePort(),
    );
    final api = ExperienceApi(application: application);
    return ExperienceComponents(application: application, api: api);
  }
}

/// Wired Experience capabilities for composition / tests.
final class ExperienceComponents {
  const ExperienceComponents({
    required this.application,
    required this.api,
  });

  final ExperienceApplicationService application;
  final ExperienceApi api;

  Handler get handler => api.router.call;
}
