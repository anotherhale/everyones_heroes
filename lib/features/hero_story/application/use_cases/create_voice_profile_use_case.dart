import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_voice_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/voice_profile_repository.dart';

/// Creates a Hero-scoped VoiceProfile in draft lifecycle (HS.12.9).
///
/// Does not enroll, authorize cloning, or call any provider.
final class CreateVoiceProfileUseCase
    implements UseCase<CreateVoiceProfileRequest, VoiceProfile> {
  const CreateVoiceProfileUseCase({
    required VoiceProfileRepository voiceProfileRepository,
    required HeroRepository heroRepository,
    required EventBus eventBus,
  })  : _voiceProfileRepository = voiceProfileRepository,
        _heroRepository = heroRepository,
        _eventBus = eventBus;

  final VoiceProfileRepository _voiceProfileRepository;
  final HeroRepository _heroRepository;
  final EventBus _eventBus;

  @override
  Future<Result<VoiceProfile>> execute(
    CreateVoiceProfileRequest request,
  ) async {
    try {
      final hero = await _heroRepository.findById(request.ownerHeroId);
      if (hero == null) {
        return Failure('Hero not found: ${request.ownerHeroId.value}');
      }
      if (!hero.isActive) {
        return const Failure(
          'Cannot create a VoiceProfile for an archived hero.',
        );
      }

      final id = request.voiceProfileId ?? VoiceProfileId.generate();
      if (await _voiceProfileRepository.exists(id)) {
        return Failure('VoiceProfile already exists: ${id.value}');
      }

      final profile = VoiceProfile.create(
        id: id,
        ownerHeroId: request.ownerHeroId,
        language: request.language,
        referenceAudio: request.referenceAudio,
        displayName: request.displayName,
      );

      await _voiceProfileRepository.save(profile);

      for (final event in profile.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(profile);
    } catch (e) {
      return Failure('Failed to create VoiceProfile: $e');
    }
  }
}
