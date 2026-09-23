import 'package:eh_platform/src/api/api_errors.dart';
import 'package:eh_platform/src/api/middleware/auth_middleware.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/application/application_context.dart';
import 'package:eh_platform/src/identity/application/get_current_principal_query.dart';
import 'package:eh_platform/src/shared_kernel/clock.dart';
import 'package:shelf/shelf.dart';

/// Thin handler: Request → Application Query → DTO response.
///
/// No domain logic lives here.
Future<Response> handleGetMe(
  Request request, {
  required GetCurrentPrincipalHandler handler,
  required Clock clock,
}) async {
  final correlationId = correlationIdOf(request);
  final context = ApplicationContext(
    correlationId: correlationId,
    principal: principalOf(request),
    clock: clock,
  );
  final result = await handler.handle(const GetCurrentPrincipalQuery(), context);
  return result.fold(
    onSuccess: (principal) => jsonOk(
      {
        'userId': principal.userId.value,
        'displayName': principal.displayName,
      },
      correlationId: correlationId,
    ),
    onFailure: (failure) => ApiError(
      code: failure.code,
      message: failure.message,
      correlationId: correlationId,
      details: failure.details,
      statusCode: failure.code == 'unauthenticated' ? 401 : 400,
    ).toResponse(),
  );
}
