import 'package:eh_platform/src/discovery/domain/catalog/narrative_theme_reference_catalog.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeThemeReferenceCatalog (J.2 Slice 1)', () {
    test('contains exactly the 14 intended Discovery themes', () {
      final themes = NarrativeThemeReferenceCatalog.themes;
      expect(themes, hasLength(14));
      expect(themes.length, NarrativeThemeReferenceIds.all.length);
    });

    test('every theme has a stable unique ID and non-empty display name', () {
      final themes = NarrativeThemeReferenceCatalog.themes;
      final ids = <String>{};

      for (final theme in themes) {
        expect(theme.id.value, isNotEmpty);
        expect(theme.name, isNotEmpty);
        expect(theme.name, isNot(theme.id.value));
        expect(theme.description, isNotEmpty);
        expect(ids.add(theme.id.value), isTrue, reason: 'duplicate ${theme.id}');
      }
    });

    test('reference IDs match Flutter Discovery vocabulary values', () {
      expect(NarrativeThemeReferenceIds.overcomingAdversity.value,
          'overcoming-adversity');
      expect(NarrativeThemeReferenceIds.courage.value, 'courage');
      expect(NarrativeThemeReferenceIds.service.value, 'service');
      expect(NarrativeThemeReferenceIds.leadership.value, 'leadership');
      expect(NarrativeThemeReferenceIds.loss.value, 'loss');
      expect(NarrativeThemeReferenceIds.failure.value, 'failure');
      expect(NarrativeThemeReferenceIds.transformation.value, 'transformation');
      expect(NarrativeThemeReferenceIds.perseverance.value, 'perseverance');
      expect(NarrativeThemeReferenceIds.secondChances.value, 'second-chances');
      expect(NarrativeThemeReferenceIds.sacrifice.value, 'sacrifice');
      expect(NarrativeThemeReferenceIds.family.value, 'family');
      expect(NarrativeThemeReferenceIds.discovery.value, 'discovery');
      expect(NarrativeThemeReferenceIds.purpose.value, 'purpose');
      expect(NarrativeThemeReferenceIds.love.value, 'love');
    });

    test('catalog lookup is available for every reference ID', () {
      for (final id in NarrativeThemeReferenceIds.all) {
        final theme = NarrativeThemeReferenceCatalog.findById(id);
        expect(theme, isNotNull, reason: 'missing $id');
        expect(theme!.id, id);
        expect(NarrativeThemeReferenceCatalog.contains(id), isTrue);
      }
    });

    test('unknown ID is not inventable via catalog lookup', () {
      final missing = NarrativeThemeReferenceCatalog.findById(
        const NarrativeThemeId('self-discovery'),
      );
      expect(missing, isNull);
      expect(
        NarrativeThemeReferenceCatalog.contains(
          const NarrativeThemeId('not-a-theme'),
        ),
        isFalse,
      );
    });
  });
}
