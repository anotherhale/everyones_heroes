import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/enroll_voice_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/voice_profile_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_profile_port.dart';

/// Enrolls a VoiceProfile through [VoiceProfilePort] after domain authorization
/// (HS.12.9).
///
/// Does not authorize cloning. Does not enable voiceClone synthesis.
final class EnrollVoiceProfileUseCase
    implements UseCase<EnrollVoiceProfileRequest, VoiceProfile> {
  const EnrollVoiceProfileUseCase({
    required VoiceProfileRepository voiceProfileRepository,
    required VoiceProfilePort voiceProfilePort,
    required EventBus eventBus,
  })  : _voiceProfileRepository = voiceProfileRepository,
        _voiceProfilePort = voiceProfilePort,
        _eventBus = eventBus;

  final VoiceProfileRepository _voiceProfileRepository;
  final VoiceProfilePort _voiceProfilePort;
  final EventBus _eventBus;

  @override
  Future<Result<VoiceProfile>> execute(
    EnrollVoiceProfileRequest request,
  ) async {
    try {
      final profile =
          await _voiceProfileRepository.findById(request.voiceProfileId);
      if (profile == null) {
        return Failure(
          'VoiceProfile not found: ${request.voiceProfileId.value}',
        );
      }
      if (profile.ownerHeroId != request.ownerHeroId) {
        return Failure(
          'Not authorized to enroll VoiceProfile '
          '${request.voiceProfileId.value}.',
        );
      }

      if (!profile.authorization.isEnrollmentAuthorized) {
        return const Failure(
          'Cannot enroll VoiceProfile: enrollment is not authorized.',
        );
      }
      if (!profile.isEnrollable && !profile.isEnrolled) {
        return Failure(
          'Cannot enroll VoiceProfile from status '
          '${profile.lifecycleStatus.name}.',
        );
      }

      if (profile.isEnrolled) {
        return Success(profile);
      }

      final reference = request.referenceAudio ??
          (profile.referenceAudio.isNotEmpty
              ? profile.referenceAudio.first
              : null);
      if (reference == null) {
        return const Failure(
          'Cannot enroll VoiceProfile: at least one reference MediaReference '
          'is required.',
        );
      }

      await _voiceProfilePort.enroll(
        VoiceProfileEnrollmentRequest(
          ownerHeroId: profile.ownerHeroId,
          voiceProfileId: profile.id,
          referenceAudio: reference,
          language: profile.language,
          displayName: profile.displayName,
          processingVersion: request.processingVersion,
          providerHint: request.providerHint,
          modelHint: request.modelHint,
        ),
      );

      profile.markEnrolled();
      await _voiceProfileRepository.save(profile);

      for (final event in profile.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(profile);
    } on VoiceProfileException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Failed to enroll VoiceProfile: $e');
    }
  }
}
