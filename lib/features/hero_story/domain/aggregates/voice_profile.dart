import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_profile_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_created.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_deleted.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_enrolled.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_enrollment_authorized.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_revoked.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/voice_profile_authorization.dart';

/// Hero-scoped, provider-independent voice identity (HS.12.9 / HS-ADR-078).
///
/// Ownership: belongs to exactly one [HeroId]. Never Story-owned, marketplace-
/// owned, or provider-owned.
///
/// Deliberately excludes: generated audio, StoryVoiceRendering, provider SDK
/// objects, provider credentials, provider voice ids, raw audio bytes.
final class VoiceProfile extends AggregateRoot<VoiceProfileId> {
  VoiceProfile({
    required VoiceProfileId id,
    required HeroId ownerHeroId,
    required LanguageCode language,
    VoiceProfileLifecycleStatus lifecycleStatus =
        VoiceProfileLifecycleStatus.draft,
    VoiceProfileAuthorization authorization = VoiceProfileAuthorization.none,
    VoiceCloningAuthorizationScope cloningAuthorizationScope =
        VoiceCloningAuthorizationScope.perStory,
    List<MediaReference> referenceAudio = const [],
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : ownerHeroId = ownerHeroId,
        _language = language,
        _lifecycleStatus = lifecycleStatus,
        _authorization = authorization,
        _cloningAuthorizationScope = cloningAuthorizationScope,
        _referenceAudio = List<MediaReference>.of(referenceAudio),
        _displayName = _trimOrNull(displayName),
        _createdAt = createdAt ?? DateTime.now(),
        _updatedAt = updatedAt ?? createdAt ?? DateTime.now(),
        super(id);

  factory VoiceProfile.create({
    required VoiceProfileId id,
    required HeroId ownerHeroId,
    required LanguageCode language,
    List<MediaReference> referenceAudio = const [],
    String? displayName,
    DateTime? createdAt,
  }) {
    final at = createdAt ?? DateTime.now();
    final profile = VoiceProfile(
      id: id,
      ownerHeroId: ownerHeroId,
      language: language,
      // HS.12.10: new profiles default to perStory — never blank-authorize
      // every Story for the Hero.
      cloningAuthorizationScope: VoiceCloningAuthorizationScope.perStory,
      referenceAudio: referenceAudio,
      displayName: displayName,
      createdAt: at,
      updatedAt: at,
    );
    profile.raise(
      VoiceProfileCreated(
        voiceProfileId: id,
        ownerHeroId: ownerHeroId,
      ),
    );
    return profile;
  }

  /// Hero that owns this voice identity. Immutable after creation.
  final HeroId ownerHeroId;

  LanguageCode _language;
  VoiceProfileLifecycleStatus _lifecycleStatus;
  VoiceProfileAuthorization _authorization;
  VoiceCloningAuthorizationScope _cloningAuthorizationScope;
  final List<MediaReference> _referenceAudio;
  String? _displayName;
  final DateTime _createdAt;
  DateTime _updatedAt;

  LanguageCode get language => _language;
  VoiceProfileLifecycleStatus get lifecycleStatus => _lifecycleStatus;
  VoiceProfileAuthorization get authorization => _authorization;

  /// Where cloning authorization is governed for this profile (HS.12.10).
  ///
  /// Distinct from [VoiceProfileAuthorization.isCloningAuthorized].
  /// Defaults to [VoiceCloningAuthorizationScope.perStory].
  VoiceCloningAuthorizationScope get cloningAuthorizationScope =>
      _cloningAuthorizationScope;

  List<MediaReference> get referenceAudio =>
      List<MediaReference>.unmodifiable(_referenceAudio);
  String? get displayName => _displayName;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;

  bool get isDraft => _lifecycleStatus == VoiceProfileLifecycleStatus.draft;
  bool get isAuthorized =>
      _lifecycleStatus == VoiceProfileLifecycleStatus.authorized;
  bool get isEnrolled =>
      _lifecycleStatus == VoiceProfileLifecycleStatus.enrolled;
  bool get isRevoked =>
      _lifecycleStatus == VoiceProfileLifecycleStatus.revoked;
  bool get isDeleted =>
      _lifecycleStatus == VoiceProfileLifecycleStatus.deleted;

  /// Enrollment authorization granted and lifecycle is enrollable.
  bool get isEnrollable =>
      _authorization.isEnrollmentAuthorized &&
      (_lifecycleStatus == VoiceProfileLifecycleStatus.draft ||
          _lifecycleStatus == VoiceProfileLifecycleStatus.authorized);

  /// Domain-level enrollment has been recorded (not a provider SDK fact).
  bool get providerEnrollmentExists => isEnrolled;

  /// Whether future authorized voice use is permitted by lifecycle.
  bool get allowsFutureVoiceUse =>
      _lifecycleStatus.allowsFutureVoiceUse && !isDeleted;

  /// Whether story-use synthesis with this profile is currently permitted.
  ///
  /// Requires enrolled lifecycle, story-use authorization, and not revoked.
  /// Cloning authorization is intentionally not required here — cloning is a
  /// separate gate (HS-ADR-078).
  bool get maySynthesizeForStoryUse =>
      isEnrolled &&
      _authorization.isStoryUseAuthorized &&
      allowsFutureVoiceUse;

  /// Grant enrollment authorization. Transitions draft → authorized.
  ///
  /// Does not grant cloning, story-use, or publication authorization.
  /// Does not create provider enrollment.
  void authorizeEnrollment({DateTime? at}) {
    _ensureMutable();
    final when = at ?? DateTime.now();
    if (_authorization.isEnrollmentAuthorized &&
        _lifecycleStatus == VoiceProfileLifecycleStatus.authorized) {
      return;
    }

    _authorization = _authorization.grantEnrollment(when);

    if (_lifecycleStatus == VoiceProfileLifecycleStatus.draft) {
      _transitionTo(VoiceProfileLifecycleStatus.authorized, when);
      raise(
        VoiceProfileEnrollmentAuthorized(
          voiceProfileId: id,
          ownerHeroId: ownerHeroId,
        ),
      );
    } else {
      _touch(when);
    }
  }

  /// Grant cloning authorization. Independent of enrollment authorization.
  ///
  /// Does not change [cloningAuthorizationScope]. Under [perStory] scope,
  /// profile cloning authorization alone does not authorize any Story.
  void authorizeCloning({DateTime? at}) {
    _ensureMutable();
    final when = at ?? DateTime.now();
    if (_authorization.isCloningAuthorized) {
      return;
    }
    _authorization = _authorization.grantCloning(when);
    _touch(when);
  }

  /// Revoke profile-level cloning authorization.
  ///
  /// Does not change [cloningAuthorizationScope], enrollment, story-use, or
  /// publication authorization.
  void revokeCloning({DateTime? at}) {
    _ensureMutable();
    if (!_authorization.isCloningAuthorized) {
      return;
    }
    final when = at ?? DateTime.now();
    _authorization = _authorization.revokeCloning();
    _touch(when);
  }

  /// Configure where cloning authorization is governed (HS.12.10).
  ///
  /// Changing scope does **not** mutate or erase existing authorization
  /// stamps on [authorization]. Switching back to [perStory] restores the
  /// requirement for Story-level cloning authorization at evaluation time.
  void setCloningAuthorizationScope(
    VoiceCloningAuthorizationScope scope, {
    DateTime? at,
  }) {
    _ensureMutable();
    if (_cloningAuthorizationScope == scope) {
      return;
    }
    final when = at ?? DateTime.now();
    _cloningAuthorizationScope = scope;
    _touch(when);
  }

  /// Grant story-use synthesis authorization. Independent of cloning.
  void authorizeStoryUse({DateTime? at}) {
    _ensureMutable();
    final when = at ?? DateTime.now();
    if (_authorization.isStoryUseAuthorized) {
      return;
    }
    _authorization = _authorization.grantStoryUse(when);
    _touch(when);
  }

  /// Grant publication authorization. Independent of all other gates.
  void authorizePublication({DateTime? at}) {
    _ensureMutable();
    final when = at ?? DateTime.now();
    if (_authorization.isPublicationAuthorized) {
      return;
    }
    _authorization = _authorization.grantPublication(when);
    _touch(when);
  }

  /// Record domain enrollment completion after [VoiceProfilePort.enroll].
  ///
  /// Requires enrollment authorization. Does not imply cloning authorization.
  void markEnrolled({DateTime? at}) {
    _ensureMutable();
    if (!_authorization.isEnrollmentAuthorized) {
      throw StateError(
        'Cannot enroll VoiceProfile ${id.value}: enrollment is not authorized.',
      );
    }
    if (_lifecycleStatus == VoiceProfileLifecycleStatus.enrolled) {
      return;
    }
    if (_lifecycleStatus != VoiceProfileLifecycleStatus.authorized) {
      throw StateError(
        'Cannot enroll VoiceProfile ${id.value} from status '
        '${_lifecycleStatus.name}. Enrollment authorization must be granted '
        'first (draft → authorized → enrolled).',
      );
    }

    final when = at ?? DateTime.now();
    _transitionTo(VoiceProfileLifecycleStatus.enrolled, when);
    raise(
      VoiceProfileEnrolled(
        voiceProfileId: id,
        ownerHeroId: ownerHeroId,
      ),
    );
  }

  /// Revoke the profile. Blocks future authorized voice use.
  ///
  /// Does not delete generated audio; application layers enforce retention
  /// policy separately (HS-ADR-078).
  void revoke({DateTime? at}) {
    if (_lifecycleStatus == VoiceProfileLifecycleStatus.deleted) {
      throw StateError(
        'Cannot revoke a deleted VoiceProfile: ${id.value}.',
      );
    }
    if (_lifecycleStatus == VoiceProfileLifecycleStatus.revoked) {
      return;
    }
    final when = at ?? DateTime.now();
    _transitionTo(VoiceProfileLifecycleStatus.revoked, when);
    raise(
      VoiceProfileRevoked(
        voiceProfileId: id,
        ownerHeroId: ownerHeroId,
      ),
    );
  }

  /// Soft-delete the profile (terminal).
  void markDeleted({DateTime? at}) {
    if (_lifecycleStatus == VoiceProfileLifecycleStatus.deleted) {
      return;
    }
    final when = at ?? DateTime.now();
    _transitionTo(VoiceProfileLifecycleStatus.deleted, when);
    raise(
      VoiceProfileDeleted(
        voiceProfileId: id,
        ownerHeroId: ownerHeroId,
      ),
    );
  }

  /// Attach an additional reference-audio [MediaReference].
  ///
  /// Bytes remain behind a media storage port — never embedded here.
  void addReferenceAudio(MediaReference reference, {DateTime? at}) {
    _ensureMutable();
    if (_referenceAudio.any((r) => r.uri == reference.uri)) {
      return;
    }
    _referenceAudio.add(reference);
    _touch(at ?? DateTime.now());
  }

  void updateDisplayName(String? displayName, {DateTime? at}) {
    _ensureMutable();
    _displayName = _trimOrNull(displayName);
    _touch(at ?? DateTime.now());
  }

  void updateLanguage(LanguageCode language, {DateTime? at}) {
    _ensureMutable();
    _language = language;
    _touch(at ?? DateTime.now());
  }

  void _ensureMutable() {
    if (_lifecycleStatus == VoiceProfileLifecycleStatus.revoked) {
      throw StateError(
        'Cannot modify a revoked VoiceProfile: ${id.value}.',
      );
    }
    if (_lifecycleStatus == VoiceProfileLifecycleStatus.deleted) {
      throw StateError(
        'Cannot modify a deleted VoiceProfile: ${id.value}.',
      );
    }
  }

  void _transitionTo(VoiceProfileLifecycleStatus next, DateTime at) {
    if (!_lifecycleStatus.canTransitionTo(next)) {
      throw StateError(
        'Invalid VoiceProfile lifecycle transition: '
        '${_lifecycleStatus.name} → ${next.name}.',
      );
    }
    _lifecycleStatus = next;
    _updatedAt = at;
  }

  void _touch(DateTime at) {
    _updatedAt = at;
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
