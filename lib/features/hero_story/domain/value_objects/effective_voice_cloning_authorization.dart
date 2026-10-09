import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Deterministic result of evaluating whether a VoiceProfile may be used to
/// clone voice for a specific Story (HS.12.10 / HS-ADR-078).
///
/// Produced only by [VoiceCloningAuthorizationPolicy] — presentation and
/// infrastructure must not invent parallel effective-authorization logic.
final class EffectiveVoiceCloningAuthorization extends ValueObject {
  const EffectiveVoiceCloningAuthorization._({
    required this.isAllowed,
    required this.denialReason,
  });

  /// Cloning is permitted under current domain state (authorization only —
  /// does not enable production cloning / provider calls).
  static const EffectiveVoiceCloningAuthorization allowed =
      EffectiveVoiceCloningAuthorization._(
    isAllowed: true,
    denialReason: null,
  );

  factory EffectiveVoiceCloningAuthorization.denied(
    VoiceCloningDenialReason reason,
  ) {
    return EffectiveVoiceCloningAuthorization._(
      isAllowed: false,
      denialReason: reason,
    );
  }

  final bool isAllowed;
  final VoiceCloningDenialReason? denialReason;

  bool get isDenied => !isAllowed;

  @override
  List<Object?> get equalityProps => [isAllowed, denialReason];
}

/// Stable denial reasons for effective cloning authorization evaluation.
enum VoiceCloningDenialReason {
  profileDeleted,
  profileRevoked,
  profileNotEnrolled,
  ownershipMismatch,
  storyExplicitlyDenied,
  storyUseNotAuthorized,
  storyCloningNotAuthorized,
  profileCloningNotAuthorized,
}
