/// Everyone's Heroes Platform public library surface for composition & tests.
///
/// Flutter must not import this package for domain logic. Client integration
/// is via versioned REST/JSON contracts (PF-ADR-011).
library;

export 'src/ai/ai_completion_request.dart';
export 'src/ai/ai_completion_result.dart';
export 'src/ai/ai_orchestration_port.dart';
export 'src/ai/stub_ai_provider_adapter.dart';
export 'src/api/api_errors.dart';
export 'src/api/api_router.dart';
export 'src/application/application_context.dart';
export 'src/application/command.dart';
export 'src/application/query.dart';
export 'src/config/platform_config.dart';
export 'src/events/domain_event.dart';
export 'src/events/domain_event_reactor.dart';
export 'src/events/event_bus.dart';
export 'src/events/event_dispatcher.dart';
export 'src/events/event_envelope.dart';
export 'src/events/event_store.dart';
export 'src/events/in_memory_event_bus.dart';
export 'src/events/in_memory_event_dispatcher.dart';
export 'src/events/in_memory_event_store.dart';
export 'src/events/platform_started.dart';
export 'src/identity/application/get_current_principal_query.dart';
export 'src/identity/application/issue_dev_session_command.dart';
export 'src/identity/domain/authenticated_principal.dart';
export 'src/identity/domain/user.dart';
export 'src/identity/infrastructure/bearer_token_authenticator.dart';
export 'src/identity/infrastructure/identity_repository.dart';
export 'src/identity/infrastructure/postgres_identity_repository.dart';
export 'src/logging/platform_logger.dart';
export 'src/modules/discovery/discovery_module.dart';
export 'src/modules/experience/experience_module.dart';
export 'src/modules/hero_story/hero_story_module.dart';
export 'src/modules/identity/identity_module.dart';
export 'src/modules/life_journey/life_journey_module.dart';
export 'src/modules/ai/ai_module.dart';
export 'src/persistence/database.dart';
export 'src/persistence/migration_runner.dart';
export 'src/persistence/unit_of_work.dart';
export 'src/platform_composition.dart';
export 'src/platform_server.dart';
export 'src/shared_kernel/clock.dart';
export 'src/shared_kernel/guard.dart';
export 'src/shared_kernel/result.dart';
export 'src/shared_kernel/strongly_typed_id.dart';
export 'src/shared_kernel/user_id.dart';
