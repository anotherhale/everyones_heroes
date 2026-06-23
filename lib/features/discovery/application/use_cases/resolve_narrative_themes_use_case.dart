import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';

import '../../domain/repositories/discovery_profile_repository.dart';
import '../../domain/services/influence_theme_resolver.dart';

final class ResolveNarrativeThemesUseCase {
  ResolveNarrativeThemesUseCase({
    required this._repository,
    required this._resolver,
  });

  final DiscoveryProfileRepository _repository;

  final InfluenceThemeResolver _resolver;

  Future<void> execute(DiscoveryProfileId profileId) async {
    final profile = await _repository.findById(profileId);

    if (profile == null) {
      throw StateError('DiscoveryProfile not found.');
    }

    final themes = await _resolver.resolveThemes(profile.influenceIds);

    profile.replaceNarrativeThemes(themes);

    await _repository.save(profile);
  }
}
