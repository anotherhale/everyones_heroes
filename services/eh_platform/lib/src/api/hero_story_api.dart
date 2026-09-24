import 'dart:convert';
import 'dart:io';

import 'package:eh_platform/src/api/api_errors.dart';
import 'package:eh_platform/src/api/middleware/auth_middleware.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/hero_story/application/use_cases/project_discoverable_story_candidate_use_case.dart';
import 'package:eh_platform/src/hero_story/domain/models/story_candidate_eligibility_facts.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Thin HTTP adapter for Hero & Story candidate projection ingest (J.2 Slice 5).
///
/// Auth: PF.3 Identity lite Bearer principal only (no X-User-Id).
/// Does not own Story lifecycle — Flutter Story remains authoritative.
/// Does not determine Story ownership beyond Identity lite auth.
final class HeroStoryApi {
  HeroStoryApi({
    required ProjectDiscoverableStoryCandidateUseCase projectCandidate,
  }) : _projectCandidate = projectCandidate;

  final ProjectDiscoverableStoryCandidateUseCase _projectCandidate;

  Router get router {
    final router = Router();
    router.put('/v1/hero-story/candidates/<storyId>', _projectCandidateHandler);
    return router;
  }

  AuthenticatedPrincipal _requirePrincipal(Request request) {
    final principal = principalOf(request);
    if (principal == null) {
      throw _Unauthenticated();
    }
    return principal;
  }

  Future<Response> _projectCandidateHandler(
    Request request,
    String storyId,
  ) async {
    final cid = correlationIdOf(request);
    try {
      _requirePrincipal(request);

      final body = await _jsonBody(request);
      if (body == null) {
        return _apiError(
          request,
          400,
          'invalid_json',
          'Request body must be a JSON object',
        );
      }

      // Path storyId is authoritative for the projection key; body may omit it
      // or must match when present.
      final bodyStoryId = body['storyId'];
      if (bodyStoryId is String &&
          bodyStoryId.isNotEmpty &&
          bodyStoryId != storyId) {
        return _apiError(
          request,
          400,
          'validation_error',
          'storyId in body must match path parameter',
        );
      }
      body['storyId'] = storyId;

      late final StoryCandidateEligibilityFacts facts;
      try {
        facts = StoryCandidateEligibilityFacts.fromJson(body);
      } on FormatException catch (e) {
        return _apiError(
          request,
          400,
          'validation_error',
          e.message,
        );
      }

      final result = await _projectCandidate.execute(facts);
      return Response(
        200,
        body: jsonEncode(result.toJson()),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          'X-Correlation-Id': cid,
        },
      );
    } on _Unauthenticated {
      return ApiError.unauthenticated(cid).toResponse();
    } catch (e) {
      return _apiError(
        request,
        500,
        'projection_failed',
        'Failed to project discoverable story candidate: $e',
        correlationId: cid,
      );
    }
  }

  Future<Map<String, Object?>?> _jsonBody(Request request) async {
    try {
      final raw = await request.readAsString();
      if (raw.trim().isEmpty) {
        return <String, Object?>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
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
