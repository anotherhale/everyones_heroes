import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Structured API error envelope (PF.2 §6.5).
final class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    required this.correlationId,
    this.details = const <String, Object?>{},
    this.statusCode = 400,
  });

  final String code;
  final String message;
  final String correlationId;
  final Map<String, Object?> details;
  final int statusCode;

  Map<String, Object?> toJson() => {
        'error': {
          'code': code,
          'message': message,
          'details': details,
          'correlationId': correlationId,
        },
      };

  Response toResponse() {
    return Response(
      statusCode,
      body: jsonEncode(toJson()),
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'x-correlation-id': correlationId,
      },
    );
  }

  static ApiError unauthenticated(String correlationId) => ApiError(
        code: 'unauthenticated',
        message: 'Authentication required.',
        correlationId: correlationId,
        statusCode: 401,
      );

  static ApiError notFound(String correlationId, {String message = 'Not found'}) =>
      ApiError(
        code: 'not_found',
        message: message,
        correlationId: correlationId,
        statusCode: 404,
      );

  static ApiError internal(String correlationId, {String? message}) => ApiError(
        code: 'internal_error',
        message: message ?? 'An unexpected error occurred.',
        correlationId: correlationId,
        statusCode: 500,
      );
}

Response jsonOk(
  Object? body, {
  required String correlationId,
  int status = 200,
}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'x-correlation-id': correlationId,
    },
  );
}
