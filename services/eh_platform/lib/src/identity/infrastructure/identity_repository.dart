import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/identity/domain/user.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';

/// Persistence port for Identity lite. Domain does not depend on SQL.
abstract interface class IdentityRepository {
  Future<void> upsertUser(User user);

  Future<User?> findUserById(UserId id);

  Future<void> saveSession({
    required String tokenHash,
    required UserId userId,
    required DateTime createdAt,
    DateTime? expiresAt,
  });

  Future<AuthenticatedPrincipal?> findPrincipalByTokenHash(String tokenHash);
}
