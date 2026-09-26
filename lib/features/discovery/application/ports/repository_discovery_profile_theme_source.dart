import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/domain/repositories/discovery_profile_repository.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/discovery_profile_theme_source.dart';

/// Reads resolved [DiscoveryProfile.narrativeThemeIds] for the current local
/// user.
///
/// Themes must already be resolved onto the profile via
/// [ResolveNarrativeThemesUseCase] (Influence → NarrativeTheme). This source
/// does not re-run Influence resolution on every adaptive signal read.
final class RepositoryDiscoveryProfileThemeSource
    implements DiscoveryProfileThemeSource {
  const RepositoryDiscoveryProfileThemeSource({
    required this._discoveryProfileRepository,
    required this._currentUserId,
  });

  final DiscoveryProfileRepository _discoveryProfileRepository;
  final UserId _currentUserId;

  @override
  Future<List<NarrativeThemeId>> currentUserNarrativeThemeIds() async {
    final profile = await _discoveryProfileRepository.findByUserId(
      _currentUserId,
    );
    if (profile == null) {
      return const [];
    }
    return List.unmodifiable(profile.narrativeThemeIds);
  }
}
