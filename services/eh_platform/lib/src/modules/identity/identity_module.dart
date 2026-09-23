/// Identity module boundary (PF-ADR-002 / PF-ADR-008).
///
/// Owns: users, sessions, authz primitives.
/// Does not own: Hero profiles (Hero & Story), login-provider product UX.
final class IdentityModule {
  const IdentityModule();

  static const String name = 'identity';
}
