import 'package:eh_platform/src/application/application_context.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';

/// Query: authenticated hello / current principal (Phase 2 exit criterion).
final class GetCurrentPrincipalQuery
    implements Query<Result<AuthenticatedPrincipal>> {
  const GetCurrentPrincipalQuery();
}

final class GetCurrentPrincipalHandler
    implements
        QueryHandler<GetCurrentPrincipalQuery, Result<AuthenticatedPrincipal>> {
  const GetCurrentPrincipalHandler();

  @override
  Future<Result<AuthenticatedPrincipal>> handle(
    GetCurrentPrincipalQuery query,
    ApplicationContext context,
  ) async {
    final principal = context.principal;
    if (principal == null) {
      return const Failure(
        code: 'unauthenticated',
        message: 'Authentication required.',
      );
    }
    return Success(principal);
  }
}
