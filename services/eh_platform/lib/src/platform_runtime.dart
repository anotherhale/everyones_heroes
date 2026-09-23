import 'dart:io';

import 'package:eh_platform/src/api/life_journey_api.dart';
import 'package:eh_platform/src/eventing/event_bus.dart';
import 'package:eh_platform/src/eventing/event_dispatcher.dart';
import 'package:eh_platform/src/eventing/event_store.dart';
import 'package:eh_platform/src/eventing/in_memory_event_bus.dart';
import 'package:eh_platform/src/eventing/in_memory_event_dispatcher.dart';
import 'package:eh_platform/src/eventing/in_memory_event_store.dart';
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
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_reflection_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/services/behavioral_analysis/emoji_behavioral_evidence_analyzer.dart';
import 'package:eh_platform/src/life_journey/infrastructure/services/behavioral_analysis/rule_based_insight_extraction_service.dart';
import 'package:eh_platform/src/life_journey/infrastructure/services/behavioral_analysis/rule_based_pattern_detector.dart';
import 'package:eh_platform/src/persistence/command_idempotency_store.dart';
import 'package:eh_platform/src/persistence/unit_of_work.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Composed EH Platform runtime for H.2 (and future modules).
final class PlatformRuntime {
  PlatformRuntime._({
    required this.handler,
    required this.application,
    required this.unitOfWork,
    required this.eventStore,
    required this.eventDispatcher,
    required this.eventBus,
    required this.journeyRepository,
    required this.reflectionRepository,
    required this.idempotencyStore,
    this.connection,
  });

  final Handler handler;
  final LifeJourneyApplicationService application;
  final UnitOfWork unitOfWork;
  final EventStore eventStore;
  final EventDispatcher eventDispatcher;
  final EventBus eventBus;
  final JourneyRepository journeyRepository;
  final ReflectionRepository reflectionRepository;
  final CommandIdempotencyStore idempotencyStore;
  final Connection? connection;

  /// In-memory runtime for unit/integration tests without PostgreSQL.
  static Future<PlatformRuntime> inMemory({
    String Function(Request)? resolveUserId,
  }) async {
    final uow = InMemoryUnitOfWork();
    final journeys = OwnedInMemoryJourneyRepository();
    final reflections = OwnedInMemoryReflectionRepository();
    final idempotency = InMemoryCommandIdempotencyStore();
    return _compose(
      unitOfWork: uow,
      journeys: journeys,
      reflections: reflections,
      idempotency: idempotency,
      resolveUserId: resolveUserId ?? _defaultUserResolver,
    );
  }

  /// PostgreSQL-backed authoritative runtime.
  static Future<PlatformRuntime> postgres({
    required Connection connection,
    String Function(Request)? resolveUserId,
  }) async {
    final uow = PostgresUnitOfWork(connection);
    final journeys = PostgresJourneyRepository(unitOfWork: uow);
    final reflections = PostgresReflectionRepository(unitOfWork: uow);
    final idempotency = PostgresCommandIdempotencyStore(() => uow.session!);
    return _compose(
      unitOfWork: uow,
      journeys: journeys,
      reflections: reflections,
      idempotency: idempotency,
      resolveUserId: resolveUserId ?? _defaultUserResolver,
      connection: connection,
    );
  }

  static Future<PlatformRuntime> _compose({
    required UnitOfWork unitOfWork,
    required JourneyRepository journeys,
    required ReflectionRepository reflections,
    required CommandIdempotencyStore idempotency,
    required String Function(Request) resolveUserId,
    Connection? connection,
  }) async {
    final eventStore = InMemoryEventStore();
    final dispatcher = InMemoryEventDispatcher();
    final eventBus = InMemoryEventBus(
      eventStore: eventStore,
      dispatcher: dispatcher,
    );

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

    dispatcher.register<ReflectionSubmitted>(
      ReflectionSubmittedReactor(useCase: analyze),
    );
    dispatcher.register<BehavioralEvidenceDetected>(
      BehavioralEvidenceDetectedReactor(detectPattern: detect),
    );

    final application = LifeJourneyApplicationService(
      unitOfWork: unitOfWork,
      journeyRepository: journeys,
      reflectionRepository: reflections,
      eventBus: eventBus,
      submitReflectionUseCase: submit,
    );

    final api = LifeJourneyApi(
      application: application,
      idempotencyStore: idempotency,
      resolveUserId: resolveUserId,
    );

    final root = Router();
    root.get('/health', (_) => Response.ok('ok'));
    root.mount('/', api.router.call);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_authMiddleware(resolveUserId))
        .addHandler(root.call);

    return PlatformRuntime._(
      handler: handler,
      application: application,
      unitOfWork: unitOfWork,
      eventStore: eventStore,
      eventDispatcher: dispatcher,
      eventBus: eventBus,
      journeyRepository: journeys,
      reflectionRepository: reflections,
      idempotencyStore: idempotency,
      connection: connection,
    );
  }

  static String _defaultUserResolver(Request request) {
    final header = request.headers['x-user-id'];
    if (header != null && header.isNotEmpty) {
      return header;
    }
    final auth = request.headers[HttpHeaders.authorizationHeader];
    if (auth != null && auth.startsWith('Bearer ')) {
      final token = auth.substring(7).trim();
      if (token.isNotEmpty) {
        // Identity lite: opaque bearer token is the user id for now.
        return token;
      }
    }
    return 'dev-user';
  }

  static Middleware _authMiddleware(String Function(Request) resolveUserId) {
    return (Handler inner) {
      return (Request request) async {
        // Health is public.
        if (request.url.path == 'health' || request.url.path.isEmpty) {
          return inner(request);
        }
        // Identity lite: require bearer or X-User-Id for mutating/query APIs.
        final userId = resolveUserId(request);
        if (userId.isEmpty) {
          return Response.forbidden(
            '{"error":{"code":"unauthorized","message":"Missing identity"}}',
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          );
        }
        return inner(request);
      };
    };
  }

  Future<void> close() async {
    await connection?.close();
  }
}
