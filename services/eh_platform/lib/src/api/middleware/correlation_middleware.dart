import 'package:eh_platform/src/shared_kernel/clock.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

const String correlationIdContextKey = 'eh.correlationId';
const String principalContextKey = 'eh.principal';

/// Ensures every request has a correlation id (PF.2 §6.5).
Middleware correlationMiddleware({Uuid? uuid}) {
  final idFactory = uuid ?? const Uuid();
  return (Handler inner) {
    return (Request request) async {
      final incoming = request.headers['x-correlation-id']?.trim();
      final correlationId =
          (incoming != null && incoming.isNotEmpty) ? incoming : idFactory.v4();
      final updated = request.change(
        context: {
          ...request.context,
          correlationIdContextKey: correlationId,
        },
      );
      final response = await inner(updated);
      return response.change(
        headers: {
          ...response.headers,
          'x-correlation-id': correlationId,
        },
      );
    };
  };
}

String correlationIdOf(Request request) {
  return request.context[correlationIdContextKey] as String? ?? 'unknown';
}

/// Structured request logging with correlation id.
Middleware requestLoggingMiddleware({
  required void Function(String message, {Map<String, Object?>? fields}) log,
  Clock? clock,
}) {
  final effectiveClock = clock ?? const SystemClock();
  return (Handler inner) {
    return (Request request) async {
      final started = effectiveClock.nowUtc();
      final correlationId = correlationIdOf(request);
      log(
        'request.start',
        fields: {
          'correlationId': correlationId,
          'method': request.method,
          'path': request.requestedUri.path,
        },
      );
      try {
        final response = await inner(request);
        final elapsed =
            effectiveClock.nowUtc().difference(started).inMilliseconds;
        log(
          'request.end',
          fields: {
            'correlationId': correlationId,
            'method': request.method,
            'path': request.requestedUri.path,
            'status': response.statusCode,
            'elapsedMs': elapsed,
          },
        );
        return response;
      } catch (error) {
        log(
          'request.error',
          fields: {
            'correlationId': correlationId,
            'method': request.method,
            'path': request.requestedUri.path,
            'error': error.toString(),
          },
        );
        rethrow;
      }
    };
  };
}
