import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

import '../entities/narrative_theme.dart';

abstract interface class NarrativeThemeRepository {
  Future<NarrativeTheme?> findById(NarrativeThemeId id);

  Future<List<NarrativeTheme>> findAll();
}
