import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/repositories/discovery_profile_repository.dart';

/// Removes an Influence from the current DiscoveryProfile and re-resolves
/// Narrative Themes from the remaining Influence set (D.5).
///
/// ## Flow
///
/// ```text
/// EnsureCurrentDiscoveryProfile
///      ↓
/// DiscoveryProfile.removeInfluence
///      ↓
/// ResolveNarrativeThemes (union of remaining Influences)
///      ↓
/// Repository.save
/// ```
///
/// Preserves the invariant:
/// `profile.narrativeThemeIds == union(themes of profile.influenceIds)`.
///
/// Removing an Influence that is not on the profile is a no-op at the
/// aggregate (safe), then themes are still re-resolved from the current set.
///
/// Does **not** emit BehavioralEvidence.
/// Does **not** publish domain events onto an EventBus (deferred; aggregate
/// events are still raised by [DiscoveryProfile] for future wiring).
final class RemoveInfluenceUseCase {
  RemoveInfluenceUseCase({
    required EnsureCurrentDiscoveryProfileUseCase ensureCurrentDiscoveryProfile,
    required DiscoveryProfileRepository repository,
    required ResolveNarrativeThemesUseCase resolveNarrativeThemes,
  }) : _ensureCurrentDiscoveryProfile = ensureCurrentDiscoveryProfile,
       _repository = repository,
       _resolveNarrativeThemes = resolveNarrativeThemes;

  final EnsureCurrentDiscoveryProfileUseCase _ensureCurrentDiscoveryProfile;
  final DiscoveryProfileRepository _repository;
  final ResolveNarrativeThemesUseCase _resolveNarrativeThemes;

  /// Removes [influenceId] from the current profile and re-resolves themes.
  ///
  /// Throws [StateError] when the DiscoveryProfile cannot be loaded/saved.
  Future<DiscoveryProfile> execute(InfluenceId influenceId) async {
    final profile = await _ensureCurrentDiscoveryProfile.execute();

    profile.removeInfluence(influenceId);
    await _repository.save(profile);

    await _resolveNarrativeThemes.execute(profile.id);

    final updated = await _repository.findById(profile.id);
    if (updated == null) {
      throw StateError('DiscoveryProfile not found.');
    }
    return updated;
  }
}
