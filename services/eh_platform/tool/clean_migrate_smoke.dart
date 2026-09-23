import 'dart:io';

import 'package:eh_platform/eh_platform.dart';

/// Manual clean-database migration smoke check.
Future<void> main() async {
  final url = Platform.environment['EH_DATABASE_URL'];
  if (url == null || url.isEmpty) {
    throw StateError('EH_DATABASE_URL required');
  }
  final db = await PlatformDatabase.connect(url);
  final runner = MigrationRunner(
    database: db,
    migrationsDirectory: 'migrations',
  );
  final applied = await runner.applyPending();
  // ignore: avoid_print
  print('applied=$applied');
  final tables = await db.connection.execute('''
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'identity_users', 'identity_sessions', 'command_idempotency',
    'schema_migrations', 'journeys', 'reflections'
  )
ORDER BY 1
''');
  // ignore: avoid_print
  print('tables=${tables.map((r) => r[0]).toList()}');
  final second = await runner.applyPending();
  // ignore: avoid_print
  print('second=$second');
  await db.close();
}
