import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/identity/domain/user.dart';
import 'package:eh_platform/src/identity/infrastructure/identity_repository.dart';
import 'package:eh_platform/src/persistence/database.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';

final class PostgresIdentityRepository implements IdentityRepository {
  PostgresIdentityRepository(this._database);

  final PlatformDatabase _database;

  @override
  Future<void> upsertUser(User user) async {
    await _database.connection.execute(
      r'''
INSERT INTO identity_users (id, display_name, created_at, updated_at)
VALUES ($1::uuid, $2, $3, $3)
ON CONFLICT (id) DO UPDATE
SET display_name = EXCLUDED.display_name,
    updated_at = EXCLUDED.updated_at
''',
      parameters: [user.id.value, user.displayName, user.createdAt.toUtc()],
    );
  }

  @override
  Future<User?> findUserById(UserId id) async {
    final rows = await _database.connection.execute(
      r'''
SELECT id::text, display_name, created_at
FROM identity_users
WHERE id = $1::uuid
''',
      parameters: [id.value],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return User(
      id: UserId(row[0]! as String),
      displayName: row[1]! as String,
      createdAt: (row[2]! as DateTime).toUtc(),
    );
  }

  @override
  Future<void> saveSession({
    required String tokenHash,
    required UserId userId,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) async {
    await _database.connection.execute(
      r'''
INSERT INTO identity_sessions (token_hash, user_id, created_at, expires_at)
VALUES ($1, $2::uuid, $3, $4)
ON CONFLICT (token_hash) DO UPDATE
SET user_id = EXCLUDED.user_id,
    created_at = EXCLUDED.created_at,
    expires_at = EXCLUDED.expires_at,
    revoked_at = NULL
''',
      parameters: [
        tokenHash,
        userId.value,
        createdAt.toUtc(),
        expiresAt?.toUtc(),
      ],
    );
  }

  @override
  Future<AuthenticatedPrincipal?> findPrincipalByTokenHash(
    String tokenHash,
  ) async {
    final rows = await _database.connection.execute(
      r'''
SELECT u.id::text, u.display_name
FROM identity_sessions s
JOIN identity_users u ON u.id = s.user_id
WHERE s.token_hash = $1
  AND s.revoked_at IS NULL
  AND (s.expires_at IS NULL OR s.expires_at > NOW())
''',
      parameters: [tokenHash],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AuthenticatedPrincipal(
      userId: UserId(row[0]! as String),
      displayName: row[1]! as String,
    );
  }
}
