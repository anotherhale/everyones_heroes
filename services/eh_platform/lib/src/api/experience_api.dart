import 'dart:convert';
import 'dart:io';

import 'package:eh_platform/src/api/api_errors.dart';
import 'package:eh_platform/src/api/middleware/auth_middleware.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/experience/application/experience_application_service.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Thin HTTP adapter for Experience Selection / Today's Experience (J.1).
///
/// Auth: PF.3 Identity lite Bearer principal only (no X-User-Id).
final class ExperienceApi {
  ExperienceApi({required ExperienceApplicationService application})
      : _application = application;

  final ExperienceApplicationService _application;

  Router get router {
    final router = Router();
    router.get('/v1/experiences/today', _getTodayExperience);
    return router;
  }

  AuthenticatedPrincipal _requirePrincipal(Request request) {
    final principal = principalOf(request);
    if (principal == null) {
      throw _Unauthenticated();
    }
    return principal;
  }

  Future<Response> _getTodayExperience(Request request) async {
    try {
      final principal = _requirePrincipal(request);
      final result = await _application.getTodayExperience(
        userId: principal.userId,
      );
      return _mapResult(
        request,
        result,
        successStatus: 200,
        failureStatus: (failure) => failure.code == 'not_found' ? 404 : 400,
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
  }) {
    final cid = correlationIdOf(request);
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
      onFailure: (failure) => Response(
        failureStatus(failure),
        body: jsonEncode({
          'error': {
            'code': failure.code,
            'message': failure.message,
            'details': failure.details,
            'correlationId': cid,
          },
        }),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          'X-Correlation-Id': cid,
        },
      ),
    );
  }
}

final class _Unauthenticated implements Exception {}
