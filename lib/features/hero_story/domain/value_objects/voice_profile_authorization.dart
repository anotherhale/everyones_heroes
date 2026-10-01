import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Independent VoiceProfile authorization gates (HS.12.9 / HS-ADR-078).
///
/// These must never collapse into a single `voiceApproved` flag and must never
/// be inferred from [StoryConsent.voiceRenderingApprovedAt] (synthetic
/// narration only).
///
/// Independence rule:
///
/// ```text
/// Enrollment authorization
///         ≠
/// Cloning authorization
///         ≠
/// Story-use synthesis authorization
///         ≠
/// Publication authorization
/// ```
final class VoiceProfileAuthorization extends ValueObject {
  const VoiceProfileAuthorization({
    this.enrollmentAuthorizedAt,
    this.cloningAuthorizedAt,
    this.storyUseAuthorizedAt,
    this.publicationAuthorizedAt,
  });

  static const VoiceProfileAuthorization none = VoiceProfileAuthorization();

  /// Permission to enroll this profile (provider-neutral enrollment boundary).
  final DateTime? enrollmentAuthorizedAt;

  /// Permission to create / maintain a cloned voice representation.
  /// Independent from enrollment authorization.
  final DateTime? cloningAuthorizedAt;

  /// Permission to synthesize story narration using this profile.
  /// Independent from cloning authorization.
  final DateTime? storyUseAuthorizedAt;

  /// Permission to publish / distribute profile-backed generated audio.
  /// Independent from all other gates.
  final DateTime? publicationAuthorizedAt;

  bool get isEnrollmentAuthorized => enrollmentAuthorizedAt != null;
  bool get isCloningAuthorized => cloningAuthorizedAt != null;
  bool get isStoryUseAuthorized => storyUseAuthorizedAt != null;
  bool get isPublicationAuthorized => publicationAuthorizedAt != null;

  VoiceProfileAuthorization grantEnrollment(DateTime at) {
    return VoiceProfileAuthorization(
      enrollmentAuthorizedAt: at,
      cloningAuthorizedAt: cloningAuthorizedAt,
      storyUseAuthorizedAt: storyUseAuthorizedAt,
      publicationAuthorizedAt: publicationAuthorizedAt,
    );
  }

  VoiceProfileAuthorization grantCloning(DateTime at) {
    return VoiceProfileAuthorization(
      enrollmentAuthorizedAt: enrollmentAuthorizedAt,
      cloningAuthorizedAt: at,
      storyUseAuthorizedAt: storyUseAuthorizedAt,
      publicationAuthorizedAt: publicationAuthorizedAt,
    );
  }

  VoiceProfileAuthorization grantStoryUse(DateTime at) {
    return VoiceProfileAuthorization(
      enrollmentAuthorizedAt: enrollmentAuthorizedAt,
      cloningAuthorizedAt: cloningAuthorizedAt,
      storyUseAuthorizedAt: at,
      publicationAuthorizedAt: publicationAuthorizedAt,
    );
  }

  VoiceProfileAuthorization grantPublication(DateTime at) {
    return VoiceProfileAuthorization(
      enrollmentAuthorizedAt: enrollmentAuthorizedAt,
      cloningAuthorizedAt: cloningAuthorizedAt,
      storyUseAuthorizedAt: storyUseAuthorizedAt,
      publicationAuthorizedAt: at,
    );
  }

  VoiceProfileAuthorization revokeEnrollment() {
    return VoiceProfileAuthorization(
      enrollmentAuthorizedAt: null,
      cloningAuthorizedAt: cloningAuthorizedAt,
      storyUseAuthorizedAt: storyUseAuthorizedAt,
      publicationAuthorizedAt: publicationAuthorizedAt,
    );
  }

  VoiceProfileAuthorization revokeCloning() {
    return VoiceProfileAuthorization(
      enrollmentAuthorizedAt: enrollmentAuthorizedAt,
      cloningAuthorizedAt: null,
      storyUseAuthorizedAt: storyUseAuthorizedAt,
      publicationAuthorizedAt: publicationAuthorizedAt,
    );
  }

  VoiceProfileAuthorization revokeStoryUse() {
    return VoiceProfileAuthorization(
      enrollmentAuthorizedAt: enrollmentAuthorizedAt,
      cloningAuthorizedAt: cloningAuthorizedAt,
      storyUseAuthorizedAt: null,
      publicationAuthorizedAt: publicationAuthorizedAt,
    );
  }

  VoiceProfileAuthorization revokePublication() {
    return VoiceProfileAuthorization(
      enrollmentAuthorizedAt: enrollmentAuthorizedAt,
      cloningAuthorizedAt: cloningAuthorizedAt,
      storyUseAuthorizedAt: storyUseAuthorizedAt,
      publicationAuthorizedAt: null,
    );
  }

  @override
  List<Object?> get equalityProps => [
        enrollmentAuthorizedAt,
        cloningAuthorizedAt,
        storyUseAuthorizedAt,
        publicationAuthorizedAt,
      ];
}
