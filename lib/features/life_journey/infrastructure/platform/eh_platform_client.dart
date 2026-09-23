import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_config.dart';

/// Thin HTTP client for EH Platform H.2 commands/queries.
///
/// Does not contain domain logic — maps DTOs only.
final class EhPlatformClient {
  EhPlatformClient({
    required Uri baseUrl,
    required String authToken,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _authToken = authToken,
        _http = httpClient ?? http.Client();

  final Uri _baseUrl;
  final String _authToken;
  final http.Client _http;

  factory EhPlatformClient.fromConfig({http.Client? httpClient}) {
    final base = EhPlatformConfig.baseUrl;
    if (base == null) {
      throw StateError('EH_PLATFORM_URL is required for platform H.2 mode.');
    }
    return EhPlatformClient(
      baseUrl: base,
      authToken: EhPlatformConfig.authToken,
      httpClient: httpClient,
    );
  }

  Future<Map<String, dynamic>> createJourney({
    required String vision,
    String? journeyId,
  }) async {
    return _post('/v1/journeys', {
      'vision': vision,
      if (journeyId != null) 'journeyId': journeyId,
    });
  }

  Future<Map<String, dynamic>> getCurrentJourney() async {
    return _get('/v1/journeys/current');
  }

  Future<Map<String, dynamic>> createReflection({
    required String journeyId,
    String? reflectionId,
  }) async {
    return _post('/v1/reflections', {
      'journeyId': journeyId,
      if (reflectionId != null) 'reflectionId': reflectionId,
    });
  }

  Future<Map<String, dynamic>> addEmojiResponse({
    required String reflectionId,
    required String emotion,
  }) async {
    return _post('/v1/reflections/$reflectionId/responses', {
      'type': 'emoji',
      'emotion': emotion,
    });
  }

  Future<Map<String, dynamic>> submitReflection({
    required String reflectionId,
    String? idempotencyKey,
  }) async {
    return _post(
      '/v1/reflections/$reflectionId/submit',
      const {},
      idempotencyKey: idempotencyKey,
    );
  }

  Future<Map<String, dynamic>> getCurrentUnderstanding() async {
    return _get('/v1/understanding/current');
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _http.get(
      _baseUrl.resolve(path),
      headers: _headers(),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body, {
    String? idempotencyKey,
  }) async {
    final response = await _http.post(
      _baseUrl.resolve(path),
      headers: {
        ..._headers(),
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, String> _headers() => {
        'content-type': 'application/json',
        'authorization': 'Bearer $_authToken',
        'x-user-id': EhPlatformConfig.userId,
      };

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] is Map
          ? ((decoded['error'] as Map)['message']?.toString() ??
              response.body)
          : response.body;
      throw EhPlatformApiException(
        statusCode: response.statusCode,
        message: message.isEmpty ? 'EH Platform request failed' : message,
      );
    }
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }
}

final class EhPlatformApiException implements Exception {
  EhPlatformApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'EhPlatformApiException($statusCode): $message';
}
