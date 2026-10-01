import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/authorize_voice_cloning_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/voice_profile_repository.dart';

/// Grants cloning authorization independently of enrollment (HS.12.9).
final class AuthorizeVoiceCloningUseCase
    implements UseCase<AuthorizeVoiceCloningRequest, VoiceProfile> {
  const AuthorizeVoiceCloningUseCase({
    required VoiceProfileRepository voiceProfileRepository,
  }) : _voiceProfileRepository = voiceProfileRepository;

  final VoiceProfileRepository _voiceProfileRepository;

  @override
  Future<Result<VoiceProfile>> execute(
    AuthorizeVoiceCloningRequest request,
  ) async {
    try {
      final loaded = await _loadOwned(
        request.voiceProfileId,
        request.ownerHeroId,
      );
      if (loaded is Failure<VoiceProfile>) {
        return loaded;
      }
      final profile = (loaded as Success<VoiceProfile>).value;

      profile.authorizeCloning(at: request.at);
      await _voiceProfileRepository.save(profile);
      return Success(profile);
    } catch (e) {
      return Failure('Failed to authorize voice cloning: $e');
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
