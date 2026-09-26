import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/discovery/domain/catalog/influence_reference_catalog.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';

void main() {
  group('InfluenceReferenceCatalog', () {
    test('seeds a small curated catalog (8–15 Influences)', () {
      final influences = InfluenceReferenceCatalog.influences;

      expect(influences.length, inInclusiveRange(8, 15));
      expect(influences.length, InfluenceReferenceIds.all.length);
    });

    test('uses only NarrativeThemeReferenceCatalog theme IDs', () {
      final allowed = NarrativeThemeReferenceIds.all.toSet();

      for (final influence in InfluenceReferenceCatalog.influences) {
        expect(influence.narrativeThemeIds, isNotEmpty);
        for (final themeId in influence.narrativeThemeIds) {
          expect(
            allowed.contains(themeId),
            isTrue,
            reason: '${influence.canonicalName} uses unknown theme '
                '${themeId.value}',
          );
        }
      }
    });

    test('uses stable InfluenceIds from InfluenceReferenceIds', () {
      final ids = InfluenceReferenceCatalog.influences
          .map((influence) => influence.id)
          .toSet();

      expect(ids, InfluenceReferenceIds.all.toSet());
    });

    test('InMemoryInfluenceRepository.withReferenceCatalog resolves IDs',
        () async {
      final repo = InMemoryInfluenceRepository.withReferenceCatalog();

      for (final id in InfluenceReferenceIds.all) {
        final influence = await repo.findById(id);
        expect(influence, isNotNull);
        expect(influence!.id, id);
      }

      final all = await repo.findAll();
      expect(all, hasLength(InfluenceReferenceIds.all.length));
    });
  });
}
