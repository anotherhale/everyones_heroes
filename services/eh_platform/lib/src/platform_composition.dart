import 'dart:io';

import 'package:eh_platform/src/ai/ai_orchestration_port.dart';
import 'package:eh_platform/src/ai/stub_ai_provider_adapter.dart';
import 'package:eh_platform/src/api/api_router.dart';
import 'package:eh_platform/src/api/middleware/auth_middleware.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/api/middleware/error_middleware.dart';
import 'package:eh_platform/src/application/application_context.dart';
import 'package:eh_platform/src/config/platform_config.dart';
import 'package:eh_platform/src/events/event_bus.dart';
import 'package:eh_platform/src/events/event_dispatcher.dart';
import 'package:eh_platform/src/events/event_store.dart';
import 'package:eh_platform/src/events/in_memory_event_bus.dart';
import 'package:eh_platform/src/events/in_memory_event_dispatcher.dart';
import 'package:eh_platform/src/events/in_memory_event_store.dart';
import 'package:eh_platform/src/events/platform_started.dart';
import 'package:eh_platform/src/identity/application/get_current_principal_query.dart';
import 'package:eh_platform/src/identity/application/issue_dev_session_command.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/identity/infrastructure/bearer_token_authenticator.dart';
import 'package:eh_platform/src/identity/infrastructure/identity_repository.dart';
import 'package:eh_platform/src/identity/infrastructure/postgres_identity_repository.dart';
import 'package:eh_platform/src/logging/platform_logger.dart';
import 'package:eh_platform/src/modules/life_journey/life_journey_module.dart';
import 'package:eh_platform/src/persistence/database.dart';
import 'package:eh_platform/src/persistence/migration_runner.dart';
import 'package:eh_platform/src/persistence/unit_of_work.dart';
import 'package:eh_platform/src/shared_kernel/clock.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

/// Composition root for the EH Platform modular monolith.
final class PlatformComposition {
  PlatformComposition._({
    required this.config,
    required this.logger,
    required this.clock,
    required this.database,
    required this.unitOfWork,
    required this.eventStore,
    required this.eventDispatcher,
    required this.eventBus,
    required this.identityRepository,
    required this.authenticator,
    required this.getCurrentPrincipalHandler,
    required this.issueDevSessionHandler,
    required this.aiOrchestration,
    required this.lifeJourney,
    required this.handler,
    required this.migrationsDirectory,
  });

  final PlatformConfig config;
  final PlatformLogger logger;
  final Clock clock;
  final PlatformDatabase database;
  final UnitOfWork unitOfWork;
  final EventStore eventStore;
  final EventDispatcher eventDispatcher;
  final EventBus eventBus;
  final IdentityRepository identityRepository;
  final BearerTokenAuthenticator authenticator;
  final GetCurrentPrincipalHandler getCurrentPrincipalHandler;
  final IssueDevSessionHandler issueDevSessionHandler;
  final AiOrchestrationPort aiOrchestration;
  final LifeJourneyComponents lifeJourney;
  final Handler handler;
  final String migrationsDirectory;

  static Future<PlatformComposition> bootstrap({
    required PlatformConfig config,
    Clock? clock,
    PlatformLogger? logger,
    String? migrationsDirectory,
    String? openApiDocumentPath,
    Uuid? uuid,
  }) async {
    final effectiveClock = clock ?? const SystemClock();
    final effectiveLogger = logger ??
        PlatformLogger(minLevel: PlatformLogger.parseLevel(config.logLevel));
    final migrationsDir =
        migrationsDirectory ?? _defaultMigrationsDirectory();
    final openApiPath = openApiDocumentPath ?? _defaultOpenApiPath();
    final idFactory = uuid ?? const Uuid();

    effectiveLogger.info(
      'platform.bootstrap.start',
      fields: {
        'environment': config.environment,
        'port': config.port,
      },
    );

    final database = await PlatformDatabase.connect(config.databaseUrl);
    final migrationRunner = MigrationRunner(
      database: database,
      migrationsDirectory: migrationsDir,
    );
    final applied = await migrationRunner.applyPending();
    effectiveLogger.info(
      'platform.migrations.applied',
      fields: {'versions': applied},
    );

    final eventStore = InMemoryEventStore();
    final eventDispatcher = InMemoryEventDispatcher();
    final eventBus = InMemoryEventBus(
      eventStore: eventStore,
      dispatcher: eventDispatcher,
    );

    final identityRepository = PostgresIdentityRepository(database);
    final unitOfWork = UnitOfWork(database);

    final fallbackPrincipal = AuthenticatedPrincipal(
      userId: UserId(config.devUserId),
      displayName: config.devUserDisplayName,
    );

    // Ensure development principal exists for authenticated hello path.
    if (config.isDevelopment) {
      await IssueDevSessionHandler(identityRepository: identityRepository)
          .handle(
        IssueDevSessionCommand(
          userId: UserId(config.devUserId),
          displayName: config.devUserDisplayName,
          token: config.devAuthToken,
        ),
        ApplicationContext(
          correlationId: idFactory.v4(),
          clock: effectiveClock,
        ),
      );
    }

    final authenticator = BearerTokenAuthenticator(
      identityRepository: identityRepository,
      developmentFallbackToken:
          config.isDevelopment ? config.devAuthToken : null,
      developmentFallbackPrincipal:
          config.isDevelopment ? fallbackPrincipal : null,
    );

    const aiOrchestration = StubAiProviderAdapter();

    final lifeJourney = LifeJourneyModule.composePostgres(
      database: database,
      unitOfWork: unitOfWork,
      eventBus: eventBus,
      eventDispatcher: eventDispatcher,
    );

    final openApiDocument = File(openApiPath).existsSync()
        ? await File(openApiPath).readAsString()
        : '';

    final apiRouter = ApiRouter(
      database: database,
      getCurrentPrincipalHandler: const GetCurrentPrincipalHandler(),
      clock: effectiveClock,
      openApiDocument: openApiDocument,
      lifeJourneyApi: lifeJourney.api,
    );

    final handler = const Pipeline()
        .addMiddleware(errorHandlingMiddleware(logger: effectiveLogger))
        .addMiddleware(correlationMiddleware(uuid: idFactory))
        .addMiddleware(
          requestLoggingMiddleware(
            log: effectiveLogger.info,
            clock: effectiveClock,
          ),
        )
        .addMiddleware(authenticationMiddleware(authenticator: authenticator))
        .addHandler(apiRouter.build());

    final composition = PlatformComposition._(
      config: config,
      logger: effectiveLogger,
      clock: effectiveClock,
      database: database,
      unitOfWork: unitOfWork,
      eventStore: eventStore,
      eventDispatcher: eventDispatcher,
      eventBus: eventBus,
      identityRepository: identityRepository,
      authenticator: authenticator,
      getCurrentPrincipalHandler: const GetCurrentPrincipalHandler(),
      issueDevSessionHandler:
          IssueDevSessionHandler(identityRepository: identityRepository),
      aiOrchestration: aiOrchestration,
      lifeJourney: lifeJourney,
      handler: handler,
      migrationsDirectory: migrationsDir,
    );

    await eventBus.publish(
      PlatformStarted(
        eventId: idFactory.v4(),
        occurredAt: effectiveClock.nowUtc(),
        environment: config.environment,
        httpPort: config.port,
        correlationId: idFactory.v4(),
      ),
    );

    effectiveLogger.info(
      'platform.bootstrap.complete',
      fields: {
        'modules': const [
          'identity',
          'life_journey',
          'discovery',
          'hero_story',
          'experience',
          'ai',
          'shared_kernel',
        ],
      },
    );

    return composition;
  }

  Future<void> close() async {
    logger.info('platform.shutdown.start');
    await database.close();
    logger.info('platform.shutdown.complete');
  }

  static String _defaultMigrationsDirectory() {
    return File.fromUri(Platform.script)
        .parent
        .parent
        .uri
        .resolve('migrations')
        .toFilePath();
  }

  static String _defaultOpenApiPath() {
    return File.fromUri(Platform.script)
        .parent
        .parent
        .uri
        .resolve('openapi/openapi.v1.json')
        .toFilePath();
  }
}
