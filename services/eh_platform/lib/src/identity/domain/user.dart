import 'package:eh_platform/src/shared_kernel/guard.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';

/// Platform User aggregate root (Identity lite — PF-ADR-008).
///
/// Intentionally minimal. Login providers are product-open; this model only
/// establishes the authenticated-user abstraction.
final class User {
  User({
    required this.id,
    required this.displayName,
    required this.createdAt,
  }) {
    Guard.againstNullOrEmpty(displayName, 'displayName');
  }

  final UserId id;
  final String displayName;
  final DateTime createdAt;
}
