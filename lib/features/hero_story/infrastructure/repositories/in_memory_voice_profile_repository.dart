import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_profile_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/voice_profile_repository.dart';

/// In-memory [VoiceProfileRepository] for tests and local development (HS.12.9).
///
/// Not durable persistence. Provider enrollment bindings are not stored here.
final class InMemoryVoiceProfileRepository implements VoiceProfileRepository {
  final Map<VoiceProfileId, VoiceProfile> _store = {};

  @override
  Future<void> save(VoiceProfile profile) async {
    _store[profile.id] = profile;
  }

  @override
  Future<VoiceProfile?> findById(VoiceProfileId id) async {
    return _store[id];
  }

  @override
  Future<List<VoiceProfile>> findByHeroId(
    HeroId heroId, {
    bool includeDeleted = false,
  }) async {
    return List.unmodifiable(
      _store.values.where((profile) {
        if (profile.ownerHeroId != heroId) {
          return false;
        }
        if (!includeDeleted &&
            profile.lifecycleStatus == VoiceProfileLifecycleStatus.deleted) {
          return false;
        }
        return true;
      }),
    );
  }

  @override
  Future<bool> exists(VoiceProfileId id) async {
    return _store.containsKey(id);
  }

  @override
  Future<void> delete(VoiceProfileId id) async {
    _store.remove(id);
  }

  void clear() => _store.clear();

  int get count => _store.length;
}
