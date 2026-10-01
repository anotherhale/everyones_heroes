import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/revoke_voice_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/voice_profile_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_profile_port.dart';

/// Revokes a VoiceProfile, blocking future authorized voice use (HS.12.9).
///
/// Does not delete generated StoryVoiceRendering audio; retention policy is
/// deferred.
final class RevokeVoiceProfileUseCase
    implements UseCase<RevokeVoiceProfileRequest, VoiceProfile> {
  const RevokeVoiceProfileUseCase({
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
    RevokeVoiceProfileRequest request,
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
          'Not authorized to revoke VoiceProfile '
          '${request.voiceProfileId.value}.',
        );
      }

      if (profile.isRevoked) {
        return Success(profile);
      }

      // Best-effort infrastructure revoke; domain remains source of truth.
      await _voiceProfilePort.revoke(profile.id);

      profile.revoke();
      await _voiceProfileRepository.save(profile);

      for (final event in profile.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(profile);
    } on VoiceProfileException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Failed to revoke VoiceProfile: $e');
    }
  }
}
