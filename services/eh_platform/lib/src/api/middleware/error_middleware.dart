import 'package:eh_platform/src/api/api_errors.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/logging/platform_logger.dart';
import 'package:shelf/shelf.dart';

/// Converts unexpected errors into the structured error envelope.
Middleware errorHandlingMiddleware({required PlatformLogger logger}) {
  return (Handler inner) {
    return (Request request) async {
      try {
        return await inner(request);
      } catch (error, stackTrace) {
        final correlationId = correlationIdOf(request);
        logger.error(
          'unhandled.error',
          fields: {
            'correlationId': correlationId,
            'stack': stackTrace.toString(),
          },
          error: error,
        );
        return ApiError.internal(correlationId).toResponse();
      }
    };
  };
}
