import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

abstract interface class InfluenceThemeResolver {
  Future<List<NarrativeThemeId>> resolveThemes(
    Iterable<InfluenceId> influenceIds,
  );
}
