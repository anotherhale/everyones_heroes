import 'dart:io';

import 'package:eh_platform/src/persistence/database.dart';

/// Applies ordered SQL migration files from a directory.
final class MigrationRunner {
  MigrationRunner({
    required this._database,
    required this.migrationsDirectory,
  });

  final PlatformDatabase _database;
  final String migrationsDirectory;

  Future<List<String>> applyPending() async {
    await _database.connection.execute('''
CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
''');

    final applied = <String>{};
    final rows = await _database.connection.execute(
      'SELECT version FROM schema_migrations ORDER BY version',
    );
    for (final row in rows) {
      applied.add(row[0] as String);
    }

    final dir = Directory(migrationsDirectory);
    if (!dir.existsSync()) {
      throw StateError('Migrations directory not found: $migrationsDirectory');
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => _basename(a.path).compareTo(_basename(b.path)));

    final newlyApplied = <String>[];
    for (final file in files) {
      final version = _basename(file.path);
      if (applied.contains(version)) continue;

      final sql = await file.readAsString();
      final statements = _splitStatements(sql);
      await _database.runInTransaction((session) async {
        for (final statement in statements) {
          await session.execute(statement);
        }
        await session.execute(
          r'INSERT INTO schema_migrations (version) VALUES ($1)',
          parameters: [version],
        );
      });
      newlyApplied.add(version);
    }
    return newlyApplied;
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index < 0 ? normalized : normalized.substring(index + 1);
  }

  /// Splits a SQL file into individual statements (naive; sufficient for PF.3).
  static List<String> _splitStatements(String sql) {
    final withoutComments = sql
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('--'))
        .join('\n');
    return withoutComments
        .split(';')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
}
