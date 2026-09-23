import 'package:eh_platform/src/shared_kernel/user_id.dart';

/// Authenticated caller resolved from a bearer token.
///
/// Provider-agnostic — can later map OAuth/email to the same principal shape.
final class AuthenticatedPrincipal {
  const AuthenticatedPrincipal({
    required this.userId,
    required this.displayName,
  });

  final UserId userId;
  final String displayName;

  Map<String, Object?> toJson() => {
        'userId': userId.value,
        'displayName': displayName,
      };
}
