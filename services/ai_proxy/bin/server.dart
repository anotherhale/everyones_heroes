import 'dart:io';

import 'package:ai_proxy/ai_proxy.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Everyone's Heroes AI proxy entrypoint (HS.11).
///
/// Environment:
/// - `OPENAI_API_KEY` (required)
/// - `OPENAI_TRANSCRIPTION_MODEL` (optional, default gpt-4o-mini-transcribe)
/// - `OPENAI_BASE_URL` (optional)
/// - `EH_AI_PROXY_HOST` / `EH_AI_PROXY_PORT`
/// - `EH_AI_PROXY_AUTH_TOKEN` (optional bearer token)
Future<void> main(List<String> args) async {
  final config = ProxyConfig.fromEnvironment();
  final handler = StoryTranscriptionHandler(config: config);
  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(handler.authMiddleware)
      .addHandler(handler.router.call);

  final server = await shelf_io.serve(
    pipeline,
    config.host == '0.0.0.0' ? InternetAddress.anyIPv4 : config.host,
    config.port,
  );
  // ignore: avoid_print
  print(
    'EH AI proxy listening on http://${server.address.host}:${server.port}',
  );
}
