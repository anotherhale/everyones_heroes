import 'package:eh_platform/src/api/api_errors.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/identity/infrastructure/bearer_token_authenticator.dart';
import 'package:shelf/shelf.dart';

/// Resolves bearer auth into request context. Does not force auth on all routes.
Middleware authenticationMiddleware({
  required BearerTokenAuthenticator authenticator,
}) {
  return (Handler inner) {
    return (Request request) async {
      final principal = await authenticator.authenticate(
        request.headers['authorization'],
      );
      final updated = principal == null
          ? request
          : request.change(
              context: {
                ...request.context,
                principalContextKey: principal,
              },
            );
      return inner(updated);
    };
  };
}

AuthenticatedPrincipal? principalOf(Request request) {
  return request.context[principalContextKey] as AuthenticatedPrincipal?;
}

/// Requires an authenticated principal for protected routes.
Middleware requireAuth() {
  return (Handler inner) {
    return (Request request) async {
      final principal = principalOf(request);
      if (principal == null) {
        return ApiError.unauthenticated(correlationIdOf(request)).toResponse();
      }
      return inner(request);
    };
  };
}
