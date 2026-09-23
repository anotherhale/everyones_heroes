import 'dart:async';
import 'dart:io';

import 'package:eh_platform/src/config/platform_config.dart';
import 'package:eh_platform/src/platform_composition.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// HTTP server lifecycle with graceful shutdown.
final class PlatformServer {
  PlatformServer({
    required this.composition,
  });

  final PlatformComposition composition;
  HttpServer? _server;

  int? get port => _server?.port;

  Future<HttpServer> start() async {
    final config = composition.config;
    final address = config.host == '0.0.0.0'
        ? InternetAddress.anyIPv4
        : InternetAddress(config.host);

    _server = await shelf_io.serve(
      composition.handler,
      address,
      config.port,
    );

    composition.logger.info(
      'platform.http.listening',
      fields: {
        'host': _server!.address.host,
        'port': _server!.port,
      },
    );
    return _server!;
  }

  Future<void> stop({Duration drainTimeout = const Duration(seconds: 5)}) async {
    final server = _server;
    if (server == null) return;
    composition.logger.info('platform.http.stopping');
    try {
      await server.close(force: false).timeout(drainTimeout);
    } on TimeoutException {
      await server.close(force: true);
    }
    _server = null;
    await composition.close();
  }
}

/// Loads config, boots composition, serves HTTP, handles SIGINT/SIGTERM.
Future<void> runPlatformServer({
  Map<String, String>? environment,
  String? migrationsDirectory,
  String? openApiDocumentPath,
}) async {
  final config = PlatformConfig.fromEnvironment(environment: environment);
  final composition = await PlatformComposition.bootstrap(
    config: config,
    migrationsDirectory: migrationsDirectory,
    openApiDocumentPath: openApiDocumentPath,
  );
  final server = PlatformServer(composition: composition);
  await server.start();

  final completer = Completer<void>();
  void handleSignal(ProcessSignal signal) {
    composition.logger.info(
      'platform.signal.received',
      fields: {'signal': signal.toString()},
    );
    if (!completer.isCompleted) completer.complete();
  }

  ProcessSignal.sigint.watch().listen(handleSignal);
  // SIGTERM is available on most non-Windows platforms.
  try {
    ProcessSignal.sigterm.watch().listen(handleSignal);
  } on UnsupportedError {
    // Ignore on platforms without SIGTERM.
  }

  await completer.future;
  await server.stop();
}
