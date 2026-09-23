import 'dart:io';

import 'package:eh_platform/eh_platform.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// EH Platform entrypoint (PF.3 + H.2).
///
/// Environment:
/// - `EH_PLATFORM_HOST` / `EH_PLATFORM_PORT` (default 0.0.0.0:8080)
/// - `EH_DATABASE_URL` e.g. `postgresql://eh:eh@localhost:5432/eh_platform`
/// - `EH_PLATFORM_USE_MEMORY=true` for in-memory mode (tests / demos)
Future<void> main(List<String> args) async {
  final host = Platform.environment['EH_PLATFORM_HOST'] ?? '0.0.0.0';
  final port =
      int.tryParse(Platform.environment['EH_PLATFORM_PORT'] ?? '') ?? 8080;
  final useMemory =
      Platform.environment['EH_PLATFORM_USE_MEMORY']?.toLowerCase() == 'true';

  late final PlatformRuntime runtime;
  if (useMemory) {
    runtime = await PlatformRuntime.inMemory();
    print('EH Platform starting in MEMORY mode');
  } else {
    final url =
        Platform.environment['EH_DATABASE_URL'] ??
        'postgresql://eh:eh@localhost:5432/eh_platform';
    final uri = Uri.parse(url);
    final connection = await Connection.open(
      Endpoint(
        host: uri.host.isEmpty ? 'localhost' : uri.host,
        port: uri.hasPort ? uri.port : 5432,
        database: uri.pathSegments.isEmpty
            ? 'eh_platform'
            : uri.pathSegments.last,
        username: uri.userInfo.isEmpty
            ? 'eh'
            : Uri.decodeComponent(uri.userInfo.split(':').first),
        password: uri.userInfo.contains(':')
            ? Uri.decodeComponent(uri.userInfo.split(':').sublist(1).join(':'))
            : 'eh',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    // Apply migrations if present.
    final migration = File('migrations/001_h2_foundation.sql');
    if (migration.existsSync()) {
      for (final statement in migration.readAsStringSync().split(';')) {
        final sql = statement.trim();
        if (sql.isEmpty || sql.startsWith('--')) {
          continue;
        }
        await connection.execute(sql);
      }
    }

    runtime = await PlatformRuntime.postgres(connection: connection);
    print('EH Platform starting with PostgreSQL at $url');
  }

  final server = await shelf_io.serve(
    runtime.handler,
    host == '0.0.0.0' ? InternetAddress.anyIPv4 : host,
    port,
  );

  print(
    'EH Platform listening on http://${server.address.host}:${server.port}',
  );
}
