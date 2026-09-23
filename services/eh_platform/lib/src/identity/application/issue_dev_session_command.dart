import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:eh_platform/src/application/application_context.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/identity/domain/user.dart';
import 'package:eh_platform/src/identity/infrastructure/identity_repository.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';
import 'package:uuid/uuid.dart';

/// Development-only command to ensure a user + opaque session token exist.
///
/// Does not lock a product login provider (PF-ADR-008).
final class IssueDevSessionCommand implements Command<Result<DevSessionIssued>> {
  const IssueDevSessionCommand({
    required this.userId,
    required this.displayName,
    this.token,
  });

  final UserId userId;
  final String displayName;

  /// When null, a random opaque token is generated.
  final String? token;
}

final class DevSessionIssued {
  const DevSessionIssued({
    required this.token,
    required this.principal,
  });

  final String token;
  final AuthenticatedPrincipal principal;
}

final class IssueDevSessionHandler
    implements CommandHandler<IssueDevSessionCommand, Result<DevSessionIssued>> {
  IssueDevSessionHandler({
    required this._identityRepository,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final IdentityRepository _identityRepository;
  final Uuid _uuid;

  @override
  Future<Result<DevSessionIssued>> handle(
    IssueDevSessionCommand command,
    ApplicationContext context,
  ) async {
    final user = User(
      id: command.userId,
      displayName: command.displayName,
      createdAt: context.clock.nowUtc(),
    );
    await _identityRepository.upsertUser(user);

    final token = command.token?.trim().isNotEmpty == true
        ? command.token!.trim()
        : _uuid.v4();
    final tokenHash = hashToken(token);
    await _identityRepository.saveSession(
      tokenHash: tokenHash,
      userId: user.id,
      createdAt: context.clock.nowUtc(),
    );

    return Success(
      DevSessionIssued(
        token: token,
        principal: AuthenticatedPrincipal(
          userId: user.id,
          displayName: user.displayName,
        ),
      ),
    );
  }

  static String hashToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }
}
