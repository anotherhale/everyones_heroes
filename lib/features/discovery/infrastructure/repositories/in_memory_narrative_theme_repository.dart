import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/discovery/domain/catalog/narrative_theme_reference_catalog.dart';

import '../../domain/entities/narrative_theme.dart';
import '../../domain/repositories/narrative_theme_repository.dart';

final class InMemoryNarrativeThemeRepository
    implements NarrativeThemeRepository {
  InMemoryNarrativeThemeRepository({Iterable<NarrativeTheme>? themes}) {
    for (final theme in themes ?? const <NarrativeTheme>[]) {
      _themes[theme.id.value] = theme;
    }
  }

  /// Seeds Discovery's reference NarrativeTheme catalog (HS.FG.2).
  factory InMemoryNarrativeThemeRepository.withReferenceCatalog() {
    return InMemoryNarrativeThemeRepository(
      themes: NarrativeThemeReferenceCatalog.themes,
    );
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
