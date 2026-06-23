import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

import '../../domain/repositories/influence_repository.dart';
import '../../domain/services/influence_theme_resolver.dart';

final class InMemoryInfluenceThemeResolver implements InfluenceThemeResolver {
  InMemoryInfluenceThemeResolver({required this._influenceRepository});

  final InfluenceRepository _influenceRepository;

  @override
  Future<List<NarrativeThemeId>> resolveThemes(
    Iterable<InfluenceId> influenceIds,
  ) async {
    final results = <NarrativeThemeId>{};

    for (final influenceId in influenceIds) {
      final influence = await _influenceRepository.findById(influenceId);

      if (influence == null) {
        continue;
      }

      results.addAll(influence.narrativeThemeIds);
    }

    return results.toList(growable: false);
  }
}
