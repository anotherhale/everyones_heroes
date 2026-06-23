import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

import '../../domain/entities/narrative_theme.dart';
import '../../domain/repositories/narrative_theme_repository.dart';

final class InMemoryNarrativeThemeRepository
    implements NarrativeThemeRepository {
  InMemoryNarrativeThemeRepository({Iterable<NarrativeTheme>? themes}) {
    for (final theme in themes ?? const <NarrativeTheme>[]) {
      _themes[theme.id.value] = theme;
    }
  }

  final Map<String, NarrativeTheme> _themes = {};

  @override
  Future<NarrativeTheme?> findById(NarrativeThemeId id) async {
    return _themes[id.value];
  }

  @override
  Future<List<NarrativeTheme>> findAll() async {
    return _themes.values.toList(growable: false);
  }
}
