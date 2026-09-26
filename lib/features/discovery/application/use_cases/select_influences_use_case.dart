import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/add_influence_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/resolve_narrative_themes_use_case.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/repositories/influence_repository.dart';

/// Orchestrates curated Influence selection for the current DiscoveryProfile.
///
/// ## D.3 flow
///
/// ```text
/// EnsureCurrentDiscoveryProfile
///      ↓
/// AddInfluence (per selected InfluenceId)
///      ↓
/// ResolveNarrativeThemes
/// ```
///
/// Influence selection and theme resolution remain separate domain/application
/// concepts; this use case invokes them sequentially for the user journey.
///
/// Does **not** emit BehavioralEvidence.
/// Does **not** publish domain events onto an EventBus (deferred; aggregate
/// events are still raised by [DiscoveryProfile] for future wiring).
final class SelectInfluencesUseCase {
  SelectInfluencesUseCase({
    required this._ensureCurrentDiscoveryProfile,
    required this._addInfluence,
    required this._resolveNarrativeThemes,
    required this._influenceRepository,
  });

  final EnsureCurrentDiscoveryProfileUseCase _ensureCurrentDiscoveryProfile;
  final AddInfluenceUseCase _addInfluence;
  final ResolveNarrativeThemesUseCase _resolveNarrativeThemes;
  final InfluenceRepository _influenceRepository;

  /// Adds each Influence to the current profile, then resolves themes once.
  ///
  /// Duplicate Influence IDs are ignored by the aggregate.
  /// Unknown Influence IDs throw [StateError].
  Future<DiscoveryProfile> execute(Iterable<InfluenceId> influenceIds) async {
    final uniqueIds = influenceIds.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) {
      return _ensureCurrentDiscoveryProfile.execute();
    }

    for (final influenceId in uniqueIds) {
      final influence = await _influenceRepository.findById(influenceId);
      if (influence == null) {
        throw StateError('Influence not found: ${influenceId.value}');
      }
    }

    final profile = await _ensureCurrentDiscoveryProfile.execute();

    for (final influenceId in uniqueIds) {
      await _addInfluence.execute(
        profileId: profile.id,
        influenceId: influenceId,
      );
    }

    await _resolveNarrativeThemes.execute(profile.id);

    final updated = await _ensureCurrentDiscoveryProfile.execute();
    return updated;
  }
}
