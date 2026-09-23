import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_client.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/today_experience_cache.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/today_experience_dto.dart';

/// Platform-authoritative Today Experience (J.1).
///
/// Does **not** run local [DeterministicExperienceSelectionService] or inspect
/// Journey behavior patterns. Successful platform DTOs are authoritative.
///
/// Offline: returns last successful cached DTO when network fails; otherwise
/// unavailable failure (does not invent a local experience).
final class PlatformGetTodayExperienceUseCase
    implements GetTodayExperienceUseCase {
  PlatformGetTodayExperienceUseCase({
    required this.client,
    TodayExperienceCache? cache,
  }) : _cache = cache ?? TodayExperienceCache();

  final EhPlatformClient client;
  final TodayExperienceCache _cache;

  @override
  Future<Result<AdaptiveExperience>> execute() async {
    try {
      final json = await client.getTodayExperience();
      final dto = TodayExperienceDto.fromJson(json);
      _cache.store(dto);
      return Success(dto.toAdaptiveExperience());
    } on EhPlatformApiException catch (e) {
      if (e.statusCode == 404) {
        return const Failure('No current journey is available.');
      }
      final cached = _cache.readStale();
      if (cached != null) {
        return Success(cached.toAdaptiveExperience());
      }
      return Failure('Today experience unavailable: ${e.message}');
    } catch (e) {
      final cached = _cache.readStale();
      if (cached != null) {
        return Success(cached.toAdaptiveExperience());
      }
      return Failure('Failed to get today experience: $e');
    }
  }
}
