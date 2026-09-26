import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/repositories/discovery_profile_repository.dart';

/// Adds an inspiring Hero to the current DiscoveryProfile (D.11).
///
/// ## Flow
///
/// ```text
/// EnsureCurrentDiscoveryProfile
///      ↓
/// DiscoveryProfile.addInspiringHero
///      ↓
/// Repository.save
/// ```
///
/// Does **not** resolve Narrative Themes.
/// Does **not** emit BehavioralEvidence.
/// Does **not** affect AdaptiveDiscoverySignals / Today ranking.
/// Does **not** publish domain events onto an EventBus (deferred; aggregate
/// events are still raised by [DiscoveryProfile] for future wiring).
final class AddInspiringHeroUseCase {
  AddInspiringHeroUseCase({
    required this._ensureCurrentDiscoveryProfile,
    required this._repository,
  });

  final EnsureCurrentDiscoveryProfileUseCase _ensureCurrentDiscoveryProfile;
  final DiscoveryProfileRepository _repository;

  /// Adds [heroId] to the current profile. Duplicate adds are idempotent.
  Future<DiscoveryProfile> execute(HeroId heroId) async {
    final profile = await _ensureCurrentDiscoveryProfile.execute();

    profile.addInspiringHero(heroId);
    await _repository.save(profile);

    final updated = await _repository.findById(profile.id);
    if (updated == null) {
      throw StateError('DiscoveryProfile not found.');
    }
    return updated;
  }
}
