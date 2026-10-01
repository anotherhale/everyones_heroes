import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_profile_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Deterministic [VoiceProfilePort] for tests and local development (HS.12.9).
///
/// Creates a **synthetic** enrollment representation only. It does not call
/// any cloning provider, upload reference audio, or mint provider voice ids.
///
/// Distinct from real provider enrollment adapters (deferred).
final class InMemoryVoiceProfileAdapter implements VoiceProfilePort {
  InMemoryVoiceProfileAdapter({
    this.failWith,
    this.delay = Duration.zero,
  });

  VoiceProfileException? failWith;
  Duration delay;

  int enrollCallCount = 0;
  int revokeCallCount = 0;
  int deleteCallCount = 0;

  VoiceProfileEnrollmentRequest? lastEnrollRequest;
  VoiceProfileId? lastRevokedId;
  VoiceProfileId? lastDeletedId;

  /// Synthetic enrollment records keyed by EH [VoiceProfileId].
  ///
  /// Values are opaque labels for tests — never provider SDKs or credentials.
  final Map<VoiceProfileId, _SyntheticEnrollment> _enrollments = {};

  bool hasSyntheticEnrollment(VoiceProfileId id) =>
      _enrollments.containsKey(id);

  @override
  Future<VoiceProfileEnrollmentDraft> enroll(
    VoiceProfileEnrollmentRequest request,
  ) async {
    enrollCallCount += 1;
    lastEnrollRequest = request;
    await _maybeDelay();
    if (failWith != null) {
      throw failWith!;
    }

    if (request.referenceAudio.uri.trim().isEmpty) {
      throw const VoiceProfileException(
        'referenceAudio is required for enrollment.',
      );
    }

    final voiceProfileId =
        request.voiceProfileId ?? VoiceProfileId.generate();

    _enrollments[voiceProfileId] = _SyntheticEnrollment(
      ownerHeroId: request.ownerHeroId,
      language: request.language,
      referenceAudio: request.referenceAudio,
      displayName: request.displayName,
      processingVersion: request.processingVersion,
    );

    return VoiceProfileEnrollmentDraft(
      voiceProfileId: voiceProfileId,
      ownerHeroId: request.ownerHeroId,
      language: request.language,
      displayName: request.displayName,
      providerLabel: 'in_memory_voice_profile',
      modelLabel: request.modelHint?.trim().isNotEmpty == true
          ? request.modelHint!.trim()
          : 'synthetic-enrollment',
      processingVersion: request.processingVersion,
    );
  }

  @override
  Future<void> revoke(VoiceProfileId voiceProfileId) async {
    revokeCallCount += 1;
    lastRevokedId = voiceProfileId;
    await _maybeDelay();
    if (failWith != null) {
      throw failWith!;
    }
    // Soft revoke: keep synthetic record for audit in tests, but mark revoked.
    final existing = _enrollments[voiceProfileId];
    if (existing != null) {
      _enrollments[voiceProfileId] = existing.copyWith(revoked: true);
    }
  }

  @override
  Future<void> delete(VoiceProfileId voiceProfileId) async {
    deleteCallCount += 1;
    lastDeletedId = voiceProfileId;
    await _maybeDelay();
    if (failWith != null) {
      throw failWith!;
    }
    _enrollments.remove(voiceProfileId);
  }

  Future<void> _maybeDelay() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  void clear() {
    _enrollments.clear();
    enrollCallCount = 0;
    revokeCallCount = 0;
    deleteCallCount = 0;
    lastEnrollRequest = null;
    lastRevokedId = null;
    lastDeletedId = null;
  }
}

final class _SyntheticEnrollment {
  const _SyntheticEnrollment({
    required this.ownerHeroId,
    required this.language,
    required this.referenceAudio,
    this.displayName,
    this.processingVersion,
    this.revoked = false,
  });

  final HeroId ownerHeroId;
  final LanguageCode language;
  final MediaReference referenceAudio;
  final String? displayName;
  final String? processingVersion;
  final bool revoked;

  _SyntheticEnrollment copyWith({bool? revoked}) {
    return _SyntheticEnrollment(
      ownerHeroId: ownerHeroId,
      language: language,
      referenceAudio: referenceAudio,
      displayName: displayName,
      processingVersion: processingVersion,
      revoked: revoked ?? this.revoked,
    );
  }
}
