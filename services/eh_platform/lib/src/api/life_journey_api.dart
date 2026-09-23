import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/view_models.dart';
import 'package:eh_platform/src/life_journey/application/life_journey_application_service.dart';
import 'package:eh_platform/src/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:eh_platform/src/life_journey/domain/enums/reflection_emotion.dart';
import 'package:eh_platform/src/life_journey/domain/value_objects/journey_vision.dart';
import 'package:eh_platform/src/persistence/command_idempotency_store.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/user_id.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Thin HTTP adapter — no H.2 domain logic here.
final class LifeJourneyApi {
  LifeJourneyApi({
    required LifeJourneyApplicationService application,
    required CommandIdempotencyStore idempotencyStore,
    required String Function(Request) resolveUserId,
  }) : _application = application,
       _idempotencyStore = idempotencyStore,
       _resolveUserId = resolveUserId;

  final LifeJourneyApplicationService _application;
  final CommandIdempotencyStore _idempotencyStore;
  final String Function(Request) _resolveUserId;

  Router get router {
    final router = Router();
    router.post('/v1/journeys', _createJourney);
    router.get('/v1/journeys/current', _getCurrentJourney);
    router.post('/v1/reflections', _createReflection);
    router.post('/v1/reflections/<id>/responses', _addResponse);
    router.post('/v1/reflections/<id>:submit', _submitReflection);
    // shelf_router treats : literally in some versions — also accept slash form
    router.post('/v1/reflections/<id>/submit', _submitReflection);
    router.get('/v1/understanding/current', _getUnderstanding);
    return router;
  }

  PlatformPrincipal _principal(Request request) {
    return PlatformPrincipal(userId: UserId(_resolveUserId(request)));
  }

  Future<Response> _createJourney(Request request) async {
    final principal = _principal(request);
    final body = await _jsonBody(request);
    if (body == null) {
      return _error(400, 'invalid_json', 'Request body must be JSON object');
    }

    final visionRaw = body['vision'] as String?;
    if (visionRaw == null || visionRaw.trim().isEmpty) {
      return _error(400, 'validation_error', 'vision is required');
    }

    final journeyId = body['journeyId'] is String
        ? JourneyId(body['journeyId'] as String)
        : JourneyId.generate();

    final result = await _application.createJourney(
      principal: principal,
      request: CreateJourneyRequest(
        journeyId: journeyId,
        vision: JourneyVision(visionRaw),
      ),
    );

    return result.fold(
      onSuccess: (dto) => _json(201, dto.toJson()),
      onFailure: (e) => _error(400, 'create_journey_failed', e),
    );
  }

  Future<Response> _getCurrentJourney(Request request) async {
    final result = await _application.getCurrentJourney(
      principal: _principal(request),
    );
    return result.fold(
      onSuccess: (dto) => _json(200, dto.toJson()),
      onFailure: (e) => _error(404, 'journey_not_found', e),
    );
  }

  Future<Response> _createReflection(Request request) async {
    final body = await _jsonBody(request);
    if (body == null) {
      return _error(400, 'invalid_json', 'Request body must be JSON object');
    }
    final journeyIdRaw = body['journeyId'] as String?;
    if (journeyIdRaw == null) {
      return _error(400, 'validation_error', 'journeyId is required');
    }

    final reflectionId = body['reflectionId'] is String
        ? ReflectionId(body['reflectionId'] as String)
        : ReflectionId.generate();

    final result = await _application.createReflection(
      principal: _principal(request),
      request: CreateReflectionRequest(
        reflectionId: reflectionId,
        journeyId: JourneyId(journeyIdRaw),
      ),
    );

    return result.fold(
      onSuccess: (dto) => _json(201, dto.toJson()),
      onFailure: (e) => _error(
        e.contains('Not authorized') ? 403 : 400,
        'create_reflection_failed',
        e,
      ),
    );
  }

  Future<Response> _addResponse(Request request, String id) async {
    final body = await _jsonBody(request);
    if (body == null) {
      return _error(400, 'invalid_json', 'Request body must be JSON object');
    }

    final type = body['type'] as String? ?? 'emoji';
    if (type != 'emoji') {
      return _error(
        400,
        'unsupported_response_type',
        'H.2 migration currently accepts emoji responses only',
      );
    }
    final emotionRaw = body['emotion'] as String?;
    if (emotionRaw == null) {
      return _error(400, 'validation_error', 'emotion is required');
    }

    late final ReflectionEmotion emotion;
    try {
      emotion = ReflectionEmotion.values.byName(emotionRaw);
    } catch (_) {
      return _error(400, 'validation_error', 'Unknown emotion: $emotionRaw');
    }

    final result = await _application.addReflectionResponse(
      principal: _principal(request),
      reflectionId: ReflectionId(id),
      response: EmojiResponse(emotion: emotion),
    );

    return result.fold(
      onSuccess: (dto) => _json(200, dto.toJson()),
      onFailure: (e) => _error(
        e.contains('Not authorized')
            ? 403
            : e.contains('not found')
            ? 404
            : 400,
        'add_response_failed',
        e,
      ),
    );
  }

  Future<Response> _submitReflection(Request request, String id) async {
    final principal = _principal(request);
    final idempotencyKey = request.headers['idempotency-key'];
    final correlationId =
        request.headers['x-correlation-id'] ?? ReflectionId.generate().value;

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
      principal: principal,
      request: SubmitReflectionRequest(reflectionId: ReflectionId(id)),
    );

    final response = result.fold(
      onSuccess: (dto) =>
          _json(200, dto.toJson(), correlationId: correlationId),
      onFailure: (e) {
        final code = e.contains('already submitted')
            ? 'reflection_already_submitted'
            : e.contains('Not authorized')
            ? 'forbidden'
            : e.contains('not found')
            ? 'not_found'
            : 'submit_reflection_failed';
        final status = code == 'forbidden'
            ? 403
            : code == 'not_found'
            ? 404
            : code == 'reflection_already_submitted'
            ? 409
            : 400;
        return _error(status, code, e, correlationId: correlationId);
      },
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
  }

  Future<Response> _getUnderstanding(Request request) async {
    final result = await _application.getCurrentUnderstanding(
      principal: _principal(request),
    );
    return result.fold(
      onSuccess: (dto) => _json(200, dto.toJson()),
      onFailure: (e) => _error(404, 'understanding_not_found', e),
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

  Response _json(
    int status,
    Map<String, Object?> body, {
    String? correlationId,
  }) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        if (correlationId != null) 'X-Correlation-Id': correlationId,
      },
    );
  }

  Response _error(
    int status,
    String code,
    String message, {
    String? correlationId,
  }) {
    return _json(status, {
      'error': {
        'code': code,
        'message': message,
        'details': <String, Object?>{},
        if (correlationId != null) 'correlationId': correlationId,
      },
    }, correlationId: correlationId);
  }
}
