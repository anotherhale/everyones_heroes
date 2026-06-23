import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/services/narrative_theme_resolver.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

final class FakeNarrativeThemeResolver implements NarrativeThemeResolver {
  const FakeNarrativeThemeResolver();

  @override
  Future<List<NarrativeThemeId>> resolveThemes(Reflection reflection) async {
    if (reflection.responses.isEmpty) {
      return [];
    }

    return [NarrativeThemeId.generate()];
  }
}
