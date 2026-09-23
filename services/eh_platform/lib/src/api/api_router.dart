import 'package:eh_platform/src/api/handlers/health_handlers.dart';
import 'package:eh_platform/src/api/handlers/identity_handlers.dart';
import 'package:eh_platform/src/api/api_errors.dart';
import 'package:eh_platform/src/api/life_journey_api.dart';
import 'package:eh_platform/src/api/middleware/auth_middleware.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/identity/application/get_current_principal_query.dart';
import 'package:eh_platform/src/persistence/database.dart';
import 'package:eh_platform/src/shared_kernel/clock.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';

/// Assembles the thin HTTP surface for the platform foundation + modules.
final class ApiRouter {
  const ApiRouter({
    required this._database,
    required this._getCurrentPrincipalHandler,
    required this._clock,
    String openApiDocument = '',
    LifeJourneyApi? lifeJourneyApi,
  })  : _openApiDocument = openApiDocument,
        _lifeJourneyApi = lifeJourneyApi;

  final PlatformDatabase _database;
  final GetCurrentPrincipalHandler _getCurrentPrincipalHandler;
  final Clock _clock;
  final String _openApiDocument;
  final LifeJourneyApi? _lifeJourneyApi;

  Handler build() {
    final router = Router();

    router.get('/health', handleHealth);
    router.get('/ready', (Request request) {
      return handleReady(request, database: _database);
    });

    router.get('/v1/openapi.json', (Request request) {
      final correlationId = correlationIdOf(request);
      if (_openApiDocument.isEmpty) {
        return ApiError.notFound(
          correlationId,
          message: 'OpenAPI document not configured.',
        ).toResponse();
      }
      return Response.ok(
        _openApiDocument,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'x-correlation-id': correlationId,
        },
      );
    });

    // Authenticated hello path (Phase 2 exit criterion).
    router.get(
      '/v1/me',
      const Pipeline()
          .addMiddleware(requireAuth())
          .addHandler((Request request) {
        return handleGetMe(
          request,
          handler: _getCurrentPrincipalHandler,
          clock: _clock,
        );
      }),
    );

    final lifeJourney = _lifeJourneyApi;
    if (lifeJourney != null) {
      // H.2 routes require PF.3 Identity; mount under authenticated pipeline.
      final protected = const Pipeline()
          .addMiddleware(requireAuth())
          .addHandler(lifeJourney.router.call);
      router.mount('/', protected);
    }

    router.all('/<ignored|.*>', (Request request) {
      return ApiError.notFound(correlationIdOf(request)).toResponse();
    });

    return router.call;
  }
}

/// Parses JSON body safely for future command endpoints.
Future<Map<String, Object?>> readJsonObject(Request request) async {
  final raw = await request.readAsString();
  if (raw.trim().isEmpty) return <String, Object?>{};
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('JSON body must be an object');
}
