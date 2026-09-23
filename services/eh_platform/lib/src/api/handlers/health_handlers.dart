import 'package:eh_platform/src/api/api_errors.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/persistence/database.dart';
import 'package:shelf/shelf.dart';

/// Liveness — process is up (no dependency checks).
Response handleHealth(Request request) {
  final correlationId = correlationIdOf(request);
  return jsonOk(
    {
      'status': 'ok',
      'service': 'eh_platform',
    },
    correlationId: correlationId,
  );
}

/// Readiness — process can serve traffic (PostgreSQL reachable).
Future<Response> handleReady(
  Request request, {
  required PlatformDatabase database,
}) async {
  final correlationId = correlationIdOf(request);
  try {
    final ready = await database.isReady();
    if (!ready) {
      return ApiError(
        code: 'not_ready',
        message: 'Database readiness check failed.',
        correlationId: correlationId,
        statusCode: 503,
      ).toResponse();
    }
    return jsonOk(
      {
        'status': 'ready',
        'checks': {'database': 'ok'},
      },
      correlationId: correlationId,
    );
  } catch (error) {
    return ApiError(
      code: 'not_ready',
      message: 'Database readiness check failed.',
      correlationId: correlationId,
      details: {'error': error.toString()},
      statusCode: 503,
    ).toResponse();
  }
}
