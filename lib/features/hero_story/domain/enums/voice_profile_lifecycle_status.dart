/// Lifecycle for a Hero-owned [VoiceProfile] (HS.12.9).
///
/// Distinguishes authorization readiness from technical enrollment:
/// - [draft] — created; enrollment not yet authorized
/// - [authorized] — enrollment authorization granted; not yet enrolled
/// - [enrolled] — domain has recorded enrollment completion (active)
/// - [revoked] — future authorized voice use is blocked
/// - [deleted] — terminal soft-delete; no further transitions
///
/// Cloning / story-use / publication gates are independent of this lifecycle
/// and live on [VoiceProfileAuthorization] (HS-ADR-078).
enum VoiceProfileLifecycleStatus {
  draft,
  authorized,
  enrolled,
  revoked,
  deleted,
}

extension VoiceProfileLifecycleTransitions on VoiceProfileLifecycleStatus {
  bool canTransitionTo(VoiceProfileLifecycleStatus next) {
    switch (this) {
      case VoiceProfileLifecycleStatus.draft:
        return next == VoiceProfileLifecycleStatus.authorized ||
            next == VoiceProfileLifecycleStatus.revoked ||
            next == VoiceProfileLifecycleStatus.deleted;
      case VoiceProfileLifecycleStatus.authorized:
        return next == VoiceProfileLifecycleStatus.enrolled ||
            next == VoiceProfileLifecycleStatus.revoked ||
            next == VoiceProfileLifecycleStatus.deleted;
      case VoiceProfileLifecycleStatus.enrolled:
        return next == VoiceProfileLifecycleStatus.revoked ||
            next == VoiceProfileLifecycleStatus.deleted;
      case VoiceProfileLifecycleStatus.revoked:
        return next == VoiceProfileLifecycleStatus.deleted;
      case VoiceProfileLifecycleStatus.deleted:
        return false;
    }
  }

  /// Whether the profile may be used for future authorized voice operations.
  bool get allowsFutureVoiceUse =>
      this == VoiceProfileLifecycleStatus.authorized ||
      this == VoiceProfileLifecycleStatus.enrolled;
}
