import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/discovery/domain/repositories/narrative_theme_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_narrative_theme_repository.dart';

/// Seeded with the Discovery-owned NarrativeTheme reference catalog.
final narrativeThemeRepositoryProvider =
    Provider<NarrativeThemeRepository>((ref) {
  return InMemoryNarrativeThemeRepository.withReferenceCatalog();
});
