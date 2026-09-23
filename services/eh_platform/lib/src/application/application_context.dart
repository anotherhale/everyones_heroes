import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/shared_kernel/clock.dart';

/// Request-scoped application context (correlation + principal).
final class ApplicationContext {
  const ApplicationContext({
    required this.correlationId,
    required this.clock,
    this.principal,
    this.causationId,
  });

  final String correlationId;
  final String? causationId;
  final AuthenticatedPrincipal? principal;
  final Clock clock;

  ApplicationContext copyWith({
    AuthenticatedPrincipal? principal,
    String? causationId,
  }) {
    return ApplicationContext(
      correlationId: correlationId,
      causationId: causationId ?? this.causationId,
      principal: principal ?? this.principal,
      clock: clock,
    );
  }
}

/// Marker for application commands (state-changing operations).
abstract interface class Command<TResult> {}

/// Marker for application queries (read models / DTOs).
abstract interface class Query<TResult> {}

/// Thin application use-case contract.
abstract interface class CommandHandler<C extends Command<R>, R> {
  Future<R> handle(C command, ApplicationContext context);
}

abstract interface class QueryHandler<Q extends Query<R>, R> {
  Future<R> handle(Q query, ApplicationContext context);
}
