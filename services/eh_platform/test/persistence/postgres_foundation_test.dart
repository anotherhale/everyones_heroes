import 'dart:io';

import 'package:eh_platform/eh_platform.dart';
import 'package:test/test.dart';

import '../support/platform_paths.dart';

void main() {
  group('PostgreSQL foundation', () {
    late PlatformDatabase database;
    late String root;

    setUpAll(() async {
      root = ehPlatformRoot();
      final url = Platform.environment['EH_DATABASE_URL'] ??
          'postgres://eh:eh_dev@127.0.0.1:5432/eh_platform';
      database = await PlatformDatabase.connect(url);
    });

    tearDownAll(() async {
      await database.close();
    });

    test('connects and answers SELECT 1', () async {
      expect(await database.isReady(), isTrue);
    });

    test('applies migrations idempotently', () async {
      final runner = MigrationRunner(
        database: database,
        migrationsDirectory: '$root/migrations',
      );
      final first = await runner.applyPending();
      final second = await runner.applyPending();
      expect(second, isEmpty);
      expect(
        first.isEmpty || first.contains('001_platform_foundation.sql'),
        isTrue,
      );

      final tables = await database.connection.execute('''
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('identity_users', 'identity_sessions', 'command_idempotency')
ORDER BY table_name
''');
      final names = tables.map((row) => row[0] as String).toList();
      expect(names, containsAll(['command_idempotency', 'identity_sessions', 'identity_users']));
    });

    test('UnitOfWork commits transactional work', () async {
      final uow = UnitOfWork(database);
      final marker = 'uow-${DateTime.now().microsecondsSinceEpoch}';
      await uow.execute((session) async {
        await session.execute(
          r'''
INSERT INTO identity_users (id, display_name)
VALUES ($1::uuid, $2)
ON CONFLICT (id) DO NOTHING
''',
          parameters: [
            '00000000-0000-4000-8000-000000000077',
            marker,
          ],
        );
      });

      final rows = await database.connection.execute(
        r'''
SELECT display_name FROM identity_users WHERE id = $1::uuid
''',
        parameters: ['00000000-0000-4000-8000-000000000077'],
      );
      expect(rows, isNotEmpty);
    });
  });
}
