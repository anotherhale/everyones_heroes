import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';

abstract interface class NarrativeThemeResolver {
  Future<List<NarrativeThemeId>>
      resolveThemes(
    Reflection reflection,
  );
}