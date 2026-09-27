import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Liveness probe — auth-exempt, no upstream vendor calls.
Response handleHealth(Request request) {
  return Response.ok(
    jsonEncode(const {'status': 'ok'}),
    headers: const {'content-type': 'application/json'},
  );
}
