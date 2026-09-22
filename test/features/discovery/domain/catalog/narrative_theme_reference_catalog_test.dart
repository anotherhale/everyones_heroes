import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/discovery/domain/catalog/narrative_theme_reference_catalog.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_narrative_theme_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarrativeThemeReferenceCatalog', () {
    test('exposes stable Discovery-owned themes for every reference ID', () {
      final themes = NarrativeThemeReferenceCatalog.themes;
      expect(themes.length, NarrativeThemeReferenceIds.all.length);

      final byId = {for (final t in themes) t.id: t};
      for (final id in NarrativeThemeReferenceIds.all) {
        expect(byId.containsKey(id), isTrue, reason: 'Missing catalog entry $id');
        expect(byId[id]!.name, isNotEmpty);
        expect(byId[id]!.name, isNot(id.value));
      }
    });

    test('InMemoryNarrativeThemeRepository.withReferenceCatalog resolves IDs',
        () async {
      final repo = InMemoryNarrativeThemeRepository.withReferenceCatalog();

      for (final id in NarrativeThemeReferenceIds.all) {
        final theme = await repo.findById(id);
        expect(theme, isNotNull, reason: 'Repository missing $id');
        expect(theme!.id, id);
      }

      final all = await repo.findAll();
      expect(all.length, NarrativeThemeReferenceIds.all.length);
    });

    test('reference IDs are opaque strings, not English display labels', () {
      expect(NarrativeThemeReferenceIds.courage.value, 'courage');
      expect(NarrativeThemeReferenceIds.courage.value, isNot('Courage'));
      expect(
        NarrativeThemeReferenceIds.overcomingAdversity.value,
        'overcoming-adversity',
      );
    });

    test('unknown ID is not inventable via catalog lookup', () async {
      final repo = InMemoryNarrativeThemeRepository.withReferenceCatalog();
      final missing = await repo.findById(const NarrativeThemeId('not-a-theme'));
      expect(missing, isNull);
    });
  });
}
