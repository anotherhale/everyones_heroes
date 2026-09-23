import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:eh_platform/src/api/api_errors.dart';
import 'package:eh_platform/src/api/middleware/auth_middleware.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/life_journey_application_service.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:eh_platform/src/life_journey/domain/enums/reflection_emotion.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/persistence/command_idempotency_store.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Thin HTTP adapter — no H.2 domain logic here.
///
/// Identity comes from PF.3 [principalOf] / [requireAuth] as an
/// [AuthenticatedPrincipal] resolved by bearer session authentication.
final class LifeJourneyApi {
  LifeJourneyApi({
    required LifeJourneyApplicationService application,
    required CommandIdempotencyStore idempotencyStore,
  })  : _application = application,
        _idempotencyStore = idempotencyStore;

  final LifeJourneyApplicationService _application;
  final CommandIdempotencyStore _idempotencyStore;

  Router get router {
    final router = Router();
    router.post('/v1/journeys', _createJourney);
    router.get('/v1/journeys/current', _getCurrentJourney);
    router.post('/v1/reflections', _createReflection);
    router.post('/v1/reflections/<id>/responses', _addResponse);
    router.post('/v1/reflections/<id>/submit', _submitReflection);
    router.get('/v1/understanding/current', _getUnderstanding);
    return router;
  }

  AuthenticatedPrincipal _requirePrincipal(Request request) {
    final principal = principalOf(request);
    if (principal == null) {
      throw _Unauthenticated();
    }
    return principal;
  }

  Future<Response> _createJourney(Request request) async {
    try {
      final principal = _requirePrincipal(request);
      final body = await _jsonBody(request);
      if (body == null) {
        return _apiError(
          request,
          400,
          'invalid_json',
          'Request body must be JSON object',
        );
      }

      final visionRaw = body['vision'] as String?;
      if (visionRaw == null || visionRaw.trim().isEmpty) {
        return _apiError(
          request,
          400,
          'validation_error',
          'vision is required',
        );
      }

      final journeyId = body['journeyId'] is String
          ? JourneyId(body['journeyId'] as String)
          : JourneyId.generate();

      final result = await _application.createJourney(
        userId: principal.userId,
        request: CreateJourneyRequest(
          journeyId: journeyId,
          vision: JourneyVision(visionRaw),
        ),
      );

      return _mapResult(
        request,
        result,
        successStatus: 201,
        failureStatus: (f) => 400,
      );
    } on _Unauthenticated {
      return ApiError.unauthenticated(correlationIdOf(request)).toResponse();
    }
  }

  Future<Response> _getCurrentJourney(Request request) async {
    try {
      final principal = _requirePrincipal(request);
      final result = await _application.getCurrentJourney(
        userId: principal.userId,
      );
      return _mapResult(
        request,
        result,
        successStatus: 200,
        failureStatus: (_) => 404,
      );
    } on _Unauthenticated {
      return ApiError.unauthenticated(correlationIdOf(request)).toResponse();
    }
  }

  Future<Response> _createReflection(Request request) async {
    try {
      final principal = _requirePrincipal(request);
      final body = await _jsonBody(request);
      if (body == null) {
        return _apiError(
          request,
          400,
          'invalid_json',
          'Request body must be JSON object',
        );
      }
      final journeyIdRaw = body['journeyId'] as String?;
      if (journeyIdRaw == null) {
        return _apiError(
          request,
          400,
          'validation_error',
          'journeyId is required',
        );
      }

      final reflectionId = body['reflectionId'] is String
          ? ReflectionId(body['reflectionId'] as String)
          : ReflectionId.generate();

      final result = await _application.createReflection(
        userId: principal.userId,
        request: CreateReflectionRequest(
          reflectionId: reflectionId,
          journeyId: JourneyId(journeyIdRaw),
        ),
      );

      return _mapResult(
        request,
        result,
        successStatus: 201,
        failureStatus: (f) => f.code == 'forbidden'
            ? 403
            : f.code == 'not_found'
                ? 404
                : 400,
      );
    } on _Unauthenticated {
      return ApiError.unauthenticated(correlationIdOf(request)).toResponse();
    }
  }

  Future<Response> _addResponse(Request request, String id) async {
    try {
      final principal = _requirePrincipal(request);
      final body = await _jsonBody(request);
      if (body == null) {
        return _apiError(
          request,
          400,
          'invalid_json',
          'Request body must be JSON object',
        );
      }

      final type = body['type'] as String? ?? 'emoji';
      if (type != 'emoji') {
        return _apiError(
          request,
          400,
          'unsupported_response_type',
          'H.2 migration currently accepts emoji responses only',
        );
      }
      final emotionRaw = body['emotion'] as String?;
      if (emotionRaw == null) {
        return _apiError(
          request,
          400,
          'validation_error',
          'emotion is required',
        );
      }

      late final ReflectionEmotion emotion;
      try {
        emotion = ReflectionEmotion.values.byName(emotionRaw);
      } catch (_) {
        return _apiError(
          request,
          400,
          'validation_error',
          'Unknown emotion: $emotionRaw',
        );
      }

      final result = await _application.addReflectionResponse(
        userId: principal.userId,
        reflectionId: ReflectionId(id),
        response: EmojiResponse(emotion: emotion),
      );

      return _mapResult(
        request,
        result,
        successStatus: 200,
        failureStatus: (f) => f.code == 'forbidden'
            ? 403
            : f.code == 'not_found'
                ? 404
                : 400,
      );
    } on _Unauthenticated {
      return ApiError.unauthenticated(correlationIdOf(request)).toResponse();
    }
  }

  Future<Response> _submitReflection(Request request, String id) async {
    try {
      final principal = _requirePrincipal(request);
      final idempotencyKey = request.headers['idempotency-key'];
      final correlationId = correlationIdOf(request);

      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        final existing = await _idempotencyStore.find(
          idempotencyKey: idempotencyKey,
          userId: principal.userId,
        );
        if (existing != null) {
          return Response(
            existing.responseStatus,
            body: jsonEncode(existing.responseBody),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              'X-Correlation-Id': correlationId,
              'X-Idempotent-Replay': 'true',
            },
          );
        }
      }

      final result = await _application.submitReflection(
        userId: principal.userId,
        request: SubmitReflectionRequest(reflectionId: ReflectionId(id)),
      );

      final response = _mapResult(
        request,
        result,
        successStatus: 200,
        failureStatus: (f) {
          if (f.message.toLowerCase().contains('already submitted') ||
              f.code == 'reflection_already_submitted') {
            return 409;
          }
          if (f.code == 'forbidden') return 403;
          if (f.code == 'not_found') return 404;
          return 400;
        },
        correlationId: correlationId,
      );

      if (idempotencyKey != null &&
          idempotencyKey.isNotEmpty &&
          response.statusCode < 500) {
        final bodyBytes = await response.read().expand((c) => c).toList();
        final bodyString = utf8.decode(bodyBytes);
        final bodyMap = jsonDecode(bodyString) as Map<String, Object?>;
        await _idempotencyStore.save(
          IdempotencyRecord(
            idempotencyKey: idempotencyKey,
            userId: principal.userId,
            commandName: 'SubmitReflection',
            requestHash: sha256.convert(utf8.encode(id)).toString(),
            responseStatus: response.statusCode,
            responseBody: bodyMap,
          ),
        );
        return Response(
          response.statusCode,
          body: bodyString,
          headers: response.headers,
        );
      }

      return response;
    } on _Unauthenticated {
      return ApiError.unauthenticated(correlationIdOf(request)).toResponse();
    }
  }

  Future<Response> _getUnderstanding(Request request) async {
    try {
      final principal = _requirePrincipal(request);
      final result = await _application.getCurrentUnderstanding(
        userId: principal.userId,
      );
      return _mapResult(
        request,
        result,
        successStatus: 200,
        failureStatus: (_) => 404,
      );
    } on _Unauthenticated {
      return ApiError.unauthenticated(correlationIdOf(request)).toResponse();
    }
  }

  Response _mapResult<T>(
    Request request,
    Result<T> result, {
    required int successStatus,
    required int Function(Failure<T> failure) failureStatus,
    String? correlationId,
  }) {
    final cid = correlationId ?? correlationIdOf(request);
    return result.fold(
      onSuccess: (value) {
        final json = (value as dynamic).toJson() as Map<String, Object?>;
        return Response(
          successStatus,
          body: jsonEncode(json),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            'X-Correlation-Id': cid,
          },
        );
      },
      onFailure: (failure) => _apiError(
        request,
        failureStatus(failure),
        failure.code,
        failure.message,
        correlationId: cid,
        details: failure.details,
      ),
    );
  }

  Future<Map<String, dynamic>?> _jsonBody(Request request) async {
    try {
      final raw = await request.readAsString();
      if (raw.trim().isEmpty) {
        return <String, dynamic>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Response _apiError(
    Request request,
    int status,
    String code,
    String message, {
    String? correlationId,
    Map<String, Object?> details = const {},
  }) {
    final cid = correlationId ?? correlationIdOf(request);
    return Response(
      status,
      body: jsonEncode({
        'error': {
          'code': code,
          'message': message,
          'details': details,
          'correlationId': cid,
        },
      }),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        'X-Correlation-Id': cid,
      },
    );
  }
}

final class _Unauthenticated implements Exception {}
