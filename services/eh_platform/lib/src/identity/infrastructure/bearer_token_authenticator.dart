import 'package:eh_platform/src/identity/application/issue_dev_session_command.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/identity/infrastructure/identity_repository.dart';

/// Resolves bearer tokens to principals without locking an OAuth provider.
final class BearerTokenAuthenticator {
  BearerTokenAuthenticator({
    required this._identityRepository,
    this.developmentFallbackToken,
    this.developmentFallbackPrincipal,
  });

  final IdentityRepository _identityRepository;

  /// Optional config-level token used before DB sessions exist (boot path).
  final String? developmentFallbackToken;
  final AuthenticatedPrincipal? developmentFallbackPrincipal;

  Future<AuthenticatedPrincipal?> authenticate(String? authorizationHeader) async {
    final token = _extractBearer(authorizationHeader);
    if (token == null) return null;

    if (developmentFallbackToken != null &&
        developmentFallbackPrincipal != null &&
        token == developmentFallbackToken) {
      return developmentFallbackPrincipal;
    }

    final hash = IssueDevSessionHandler.hashToken(token);
    return _identityRepository.findPrincipalByTokenHash(hash);
  }

  static String? _extractBearer(String? header) {
    if (header == null) return null;
    final value = header.trim();
    if (value.length < 8) return null;
    if (!value.toLowerCase().startsWith('bearer ')) return null;
    final token = value.substring(7).trim();
    return token.isEmpty ? null : token;
  }
}
