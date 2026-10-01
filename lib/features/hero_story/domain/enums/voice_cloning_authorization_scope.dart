/// Where voice-cloning authorization is governed for a [VoiceProfile]
/// (HS.12.10 / HS-ADR-078).
///
/// Scope answers: "Where is cloning authorization governed?"
/// It is distinct from whether cloning has been authorized at that scope.
///
/// Default for newly created profiles is [perStory] — the most restrictive
/// mode. A new VoiceProfile must not implicitly authorize cloning of every
/// Story belonging to the Hero.
enum VoiceCloningAuthorizationScope {
  /// Cloning requires explicit Story-level cloning authorization.
  ///
  /// Profile-level cloning authorization alone does not authorize a Story.
  perStory,

  /// Explicit opt-in: profile-level cloning authorization may authorize
  /// cloning for Stories associated with this profile, subject to remaining
  /// independent gates and any explicit Story denial.
  perProfile,
}
