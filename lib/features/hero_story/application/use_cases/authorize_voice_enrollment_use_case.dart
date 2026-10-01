import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/authorize_voice_enrollment_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/voice_profile_repository.dart';

/// Grants enrollment authorization only (HS.12.9).
///
/// Does not authorize cloning, story-use, or publication, and does not enroll.
final class AuthorizeVoiceEnrollmentUseCase
    implements UseCase<AuthorizeVoiceEnrollmentRequest, VoiceProfile> {
  const AuthorizeVoiceEnrollmentUseCase({
    required VoiceProfileRepository voiceProfileRepository,
    required EventBus eventBus,
  })  : _voiceProfileRepository = voiceProfileRepository,
        _eventBus = eventBus;

  final VoiceProfileRepository _voiceProfileRepository;
  final EventBus _eventBus;

  @override
  Future<Result<VoiceProfile>> execute(
    AuthorizeVoiceEnrollmentRequest request,
  ) async {
    try {
      final profile = await _loadOwned(
        request.voiceProfileId,
        request.ownerHeroId,
      );
      if (profile is Failure<VoiceProfile>) {
        return profile;
      }
      final owned = (profile as Success<VoiceProfile>).value;

      owned.authorizeEnrollment(at: request.at);
      await _voiceProfileRepository.save(owned);

      for (final event in owned.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(owned);
    } catch (e) {
      return Failure('Failed to authorize voice enrollment: $e');
    }
  }

  Future<Result<VoiceProfile>> _loadOwned(
    VoiceProfileId id,
    HeroId ownerHeroId,
  ) async {
    final profile = await _voiceProfileRepository.findById(id);
    if (profile == null) {
      return Failure('VoiceProfile not found: ${id.value}');
    }
    if (profile.ownerHeroId != ownerHeroId) {
      return Failure(
        'Not authorized to modify VoiceProfile ${id.value} for hero '
        '${ownerHeroId.value}.',
      );
    }
    return Success(profile);
  }
}
