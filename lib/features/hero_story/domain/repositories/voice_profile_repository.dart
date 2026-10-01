import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';

/// Persistence boundary for Hero-owned VoiceProfile aggregates (HS.12.9).
///
/// Durable storage technology is deferred; in-memory implementations support
/// tests and local development. Provider enrollment bindings are not part of
/// this repository — they remain infrastructure concerns keyed by
/// [VoiceProfileId].
abstract interface class VoiceProfileRepository {
  Future<void> save(VoiceProfile profile);

  Future<VoiceProfile?> findById(VoiceProfileId id);

  /// Profiles owned by [heroId], excluding deleted unless [includeDeleted].
  Future<List<VoiceProfile>> findByHeroId(
    HeroId heroId, {
    bool includeDeleted = false,
  });

  Future<bool> exists(VoiceProfileId id);

  Future<void> delete(VoiceProfileId id);
}
