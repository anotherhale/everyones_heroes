import 'package:test/test.dart';
import 'dart:io';

/// Architecture dependency direction tests for EH Platform H.2.
void main() {
  final libRoot = Directory('lib/src');

  List<File> dartFilesUnder(String relative) {
    final dir = Directory('${libRoot.path}/$relative');
    if (!dir.existsSync()) {
      return const [];
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  bool imports(File file, String needle) {
    return file.readAsStringSync().contains(needle);
  }

  test('domain layer does not import HTTP (shelf)', () {
    for (final file in dartFilesUnder('life_journey/domain')) {
      expect(imports(file, 'package:shelf/'), isFalse, reason: file.path);
      expect(imports(file, 'package:http/'), isFalse, reason: file.path);
    }
  });

  test('domain layer does not import PostgreSQL', () {
    for (final file in dartFilesUnder('life_journey/domain')) {
      expect(imports(file, 'package:postgres/'), isFalse, reason: file.path);
    }
  });

  test('domain layer does not import AI provider SDKs', () {
    for (final file in dartFilesUnder('life_journey/domain')) {
      expect(imports(file, 'package:openai'), isFalse, reason: file.path);
      expect(imports(file, 'anthropic'), isFalse, reason: file.path);
    }
  });

  test('API layer does not import postgres directly', () {
    for (final file in dartFilesUnder('api')) {
      expect(imports(file, 'package:postgres/'), isFalse, reason: file.path);
    }
  });

  test('experience application does not import Flutter or Riverpod', () {
    for (final file in dartFilesUnder('experience')) {
      expect(imports(file, 'package:flutter/'), isFalse, reason: file.path);
      expect(imports(file, 'package:flutter_riverpod/'), isFalse,
          reason: file.path);
      expect(imports(file, 'package:openai'), isFalse, reason: file.path);
    }
  });

  test('experience selection does not live in H.2 detectors', () {
    for (final file in dartFilesUnder('life_journey/domain')) {
      expect(
        imports(file, 'deterministic_experience_selection_service.dart'),
        isFalse,
        reason: file.path,
      );
      expect(
        imports(file, 'experience_application_service.dart'),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('discovery domain does not import HTTP, PostgreSQL, or AI SDKs', () {
    for (final file in dartFilesUnder('discovery/domain')) {
      expect(imports(file, 'package:shelf/'), isFalse, reason: file.path);
      expect(imports(file, 'package:postgres/'), isFalse, reason: file.path);
      expect(imports(file, 'package:openai'), isFalse, reason: file.path);
      expect(imports(file, 'package:flutter/'), isFalse, reason: file.path);
    }
  });

  test('experience does not own NarrativeTheme catalog taxonomy', () {
    for (final file in dartFilesUnder('experience')) {
      expect(
        imports(file, 'narrative_theme_reference_catalog.dart'),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('experience does not import concrete Hero & Story candidate persistence',
      () {
    for (final file in dartFilesUnder('experience')) {
      expect(
        imports(file, 'seeded_story_candidate_catalog.dart'),
        isFalse,
        reason: file.path,
      );
      expect(
        imports(file, 'story_candidate_record.dart'),
        isFalse,
        reason: file.path,
      );
      expect(
        imports(file, 'package:postgres/'),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('discovery owns canonical theme vocabulary; HS does not redefine it', () {
    final discoveryCatalog = File(
      '${libRoot.path}/discovery/domain/catalog/narrative_theme_reference_catalog.dart',
    );
    expect(discoveryCatalog.existsSync(), isTrue);

    for (final file in dartFilesUnder('hero_story')) {
      expect(
        imports(file, 'narrative_theme_reference_catalog.dart'),
        isFalse,
        reason:
            'Hero & Story must reference NarrativeThemeReferenceIds, '
            'not redefine Discovery catalog: ${file.path}',
      );
      // HS may validate against shared-kernel ID constants, not invent themes.
      final source = file.readAsStringSync();
      expect(
        source.contains("NarrativeThemeId('invented"),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('hero_story candidate adapter depends on Experience port, not SQL', () {
    for (final file in dartFilesUnder('hero_story')) {
      expect(imports(file, 'package:postgres/'), isFalse, reason: file.path);
      expect(imports(file, 'package:shelf/'), isFalse, reason: file.path);
      expect(imports(file, 'package:flutter/'), isFalse, reason: file.path);
    }
  });
}
