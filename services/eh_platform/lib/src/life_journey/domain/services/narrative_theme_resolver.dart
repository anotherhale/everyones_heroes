import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';

import 'package:eh_platform/src/life_journey/domain/aggregates/reflection.dart';

abstract interface class NarrativeThemeResolver {
  Future<List<NarrativeThemeId>> resolveThemes(Reflection reflection);
}
