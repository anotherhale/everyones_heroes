import 'package:shelf/shelf.dart';

/// Minimal CORS for browser clients (Flutter Web → this proxy).
///
/// Test-deployment posture: reflect `Origin` when present, otherwise `*`.
/// Handles `OPTIONS` preflight before auth middleware runs.
///
/// Not an elaborate allowlist — sufficient for the initial Render web test.
Middleware corsMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final corsHeaders = _corsHeaders(request);
      if (request.method == 'OPTIONS') {
        return Response(204, headers: corsHeaders);
      }
      final response = await inner(request);
      return response.change(headers: corsHeaders);
    };
  };
}

Map<String, String> _corsHeaders(Request request) {
  final origin = request.headers['origin']?.trim();
  return {
    'Access-Control-Allow-Origin':
        (origin != null && origin.isNotEmpty) ? origin : '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
}
