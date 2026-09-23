import 'package:eh_platform/src/api/life_journey_api.dart';
import 'package:eh_platform/src/events/event_bus.dart';
import 'package:eh_platform/src/events/event_dispatcher.dart';
import 'package:eh_platform/src/life_journey/application/life_journey_application_service.dart';
import 'package:eh_platform/src/life_journey/application/providers/fake/fake_narrative_theme_resolver.dart';
import 'package:eh_platform/src/life_journey/application/reactors/behavioral_evidence_detected_reactor.dart';
import 'package:eh_platform/src/life_journey/application/reactors/reflection/reflection_submitted_reactor.dart';
import 'package:eh_platform/src/life_journey/application/services/behavioral_evidence_analysis_orchestrator.dart';
import 'package:eh_platform/src/life_journey/application/services/default_behavioral_evidence_analyzer_registry.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/analyze_reflection_use_case.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/detect_pattern_use_case.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/submit_reflection_use_case.dart';
import 'package:eh_platform/src/life_journey/domain/domain.dart';
import 'package:eh_platform/src/life_journey/infrastructure/persistence/postgres_journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/persistence/postgres_reflection_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/persistence/session_holder.dart';
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_reflection_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/services/behavioral_analysis/emoji_behavioral_evidence_analyzer.dart';
import 'package:eh_platform/src/life_journey/infrastructure/services/behavioral_analysis/rule_based_insight_extraction_service.dart';
import 'package:eh_platform/src/life_journey/infrastructure/services/behavioral_analysis/rule_based_pattern_detector.dart';
import 'package:eh_platform/src/life_journey/infrastructure/transactions/transaction_boundary.dart';
import 'package:eh_platform/src/persistence/command_idempotency_store.dart';
import 'package:eh_platform/src/persistence/database.dart';
import 'package:eh_platform/src/persistence/unit_of_work.dart';
import 'package:shelf/shelf.dart';

export 'package:eh_platform/src/life_journey/application/life_journey_application_service.dart';
export 'package:eh_platform/src/api/life_journey_api.dart';

/// Life Journey module boundary (PF-ADR-002) + H.2 composition.
///
/// Owns: Journey, Quest, Mission, Reflection, and Behavioral Understanding
/// (evidence → pattern detection). Wired into PF.3 [PlatformComposition].
final class LifeJourneyModule {
  const LifeJourneyModule();

  static const String name = 'life_journey';

  /// Behavioral Understanding remains a subdomain of Life Journey (PF-ADR-002).
  static const String behavioralUnderstandingSubdomain =
      'behavioral_understanding';

  /// Builds the H.2 stack against PF.3 events + UnitOfWork (PostgreSQL).
  static LifeJourneyComponents composePostgres({
    required PlatformDatabase database,
    required UnitOfWork unitOfWork,
    required EventBus eventBus,
    required EventDispatcher eventDispatcher,
  }) {
    final sessionHolder = SessionHolder();
    final transactions = PlatformTransactionBoundary(
      unitOfWork: unitOfWork,
      sessionHolder: sessionHolder,
    );
    final journeys = PostgresJourneyRepository(sessionHolder: sessionHolder);
    final reflections =
        PostgresReflectionRepository(sessionHolder: sessionHolder);
    final idempotency = PostgresCommandIdempotencyStore(database);

    return _compose(
      transactions: transactions,
      journeys: journeys,
      reflections: reflections,
      idempotency: idempotency,
      eventBus: eventBus,
      eventDispatcher: eventDispatcher,
    );
  }

  /// In-memory stack for unit tests (no PostgreSQL).
  static LifeJourneyComponents composeInMemory({
    required EventBus eventBus,
    required EventDispatcher eventDispatcher,
    CommandIdempotencyStore? idempotencyStore,
  }) {
    return _compose(
      transactions: const InMemoryTransactionBoundary(),
      journeys: OwnedInMemoryJourneyRepository(),
      reflections: OwnedInMemoryReflectionRepository(),
      idempotency: idempotencyStore ?? InMemoryCommandIdempotencyStore(),
      eventBus: eventBus,
      eventDispatcher: eventDispatcher,
    );
  }

  static LifeJourneyComponents _compose({
    required TransactionBoundary transactions,
    required JourneyRepository journeys,
    required ReflectionRepository reflections,
    required CommandIdempotencyStore idempotency,
    required EventBus eventBus,
    required EventDispatcher eventDispatcher,
  }) {
    final analyzers = DefaultBehavioralEvidenceAnalyzerRegistry(const [
      EmojiBehavioralEvidenceAnalyzer(),
    ]);
    final orchestrator = BehavioralEvidenceAnalysisOrchestrator(
      registry: analyzers,
    );
    final insightService = RuleBasedInsightExtractionService();
    final themeResolver = FakeNarrativeThemeResolver();
    final detector = RuleBasedPatternDetector(
      rules: [
        ConsistencyPatternRule(),
        CouragePatternRule(),
        LeadershipPatternRule(),
        ResponsibilityPatternRule(),
        ServicePatternRule(),
        RecoveryPatternRule(),
      ],
    );

    final analyze = AnalyzeReflectionUseCase(
      reflectionRepository: reflections,
      insightExtractionService: insightService,
      behavioralEvidenceAnalysisOrchestrator: orchestrator,
      narrativeThemeResolver: themeResolver,
      eventBus: eventBus,
    );

    final detect = DefaultDetectPatternUseCase(
      journeyRepository: journeys,
      reflectionRepository: reflections,
      detector: detector,
      eventBus: eventBus,
    );

    final submit = DefaultSubmitReflectionUseCase(
      reflectionRepository: reflections,
      eventBus: eventBus,
    );

    eventDispatcher.register<ReflectionSubmitted>(
      ReflectionSubmittedReactor(useCase: analyze),
    );
    eventDispatcher.register<BehavioralEvidenceDetected>(
      BehavioralEvidenceDetectedReactor(detectPattern: detect),
    );

    final application = LifeJourneyApplicationService(
      transactions: transactions,
      journeyRepository: journeys,
      reflectionRepository: reflections,
      eventBus: eventBus,
      submitReflectionUseCase: submit,
    );

    final api = LifeJourneyApi(
      application: application,
      idempotencyStore: idempotency,
    );

    return LifeJourneyComponents(
      application: application,
      api: api,
      journeyRepository: journeys,
      reflectionRepository: reflections,
      idempotencyStore: idempotency,
    );
  }
}

/// Wired Life Journey capabilities for composition / tests.
final class LifeJourneyComponents {
  const LifeJourneyComponents({
    required this.application,
    required this.api,
    required this.journeyRepository,
    required this.reflectionRepository,
    required this.idempotencyStore,
  });

  final LifeJourneyApplicationService application;
  final LifeJourneyApi api;
  final JourneyRepository journeyRepository;
  final ReflectionRepository reflectionRepository;
  final CommandIdempotencyStore idempotencyStore;

  Handler get handler => api.router.call;
}
