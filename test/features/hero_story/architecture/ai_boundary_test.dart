import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture boundary checks for HS.4 / HS.11 (no AI SDK leakage).
void main() {
  test('domain and application layers do not import AI SDKs or HTTP clients', () {
    final forbiddenImports = [
      "import 'package:openai",
      'import "package:openai',
      "import 'package:anthropic",
      'import "package:anthropic',
      "import 'package:google_generative_ai",
      'import "package:google_generative_ai',
      "import 'package:dart_openai",
      'import "package:dart_openai',
      "import 'package:langchain",
      'import "package:langchain',
      "import 'package:http/http.dart'",
      'import "package:http/http.dart"',
      "import 'package:http/",
      'import "package:http/',
    ];

    final roots = [
      Directory('lib/features/hero_story/domain'),
      Directory('lib/features/hero_story/application'),
    ];

    final offenders = <String>[];
    for (final root in roots) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final content = entity.readAsStringSync();
        for (final needle in forbiddenImports) {
          if (content.contains(needle)) {
            offenders.add('${entity.path} → $needle');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('StoryUnderstanding domain does not import Discovery theme entities', () {
    final files = Directory('lib/features/hero_story')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    final offenders = <String>[];
    for (final file in files) {
      final content = file.readAsStringSync();
      if (content.contains('features/discovery') &&
          content.contains('NarrativeTheme') &&
          !content.contains('NarrativeThemeId')) {
        offenders.add(file.path);
      }
      if (content.contains(
        "import 'package:everyonesheroes/features/discovery",
      )) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('infrastructure/ai may include proxy adapter but not vendor SDKs', () {
    final aiDir = Directory('lib/features/hero_story/infrastructure/ai');
    expect(aiDir.existsSync(), isTrue);
    final names = aiDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
    expect(names, contains('in_memory_story_transcription_adapter.dart'));
    expect(names, contains('proxy_story_transcription_adapter.dart'));
    expect(names, contains('story_transcription_config.dart'));
    expect(names, contains('in_memory_story_understanding_adapter.dart'));
    expect(
      names.any(
        (n) =>
            n.contains('openai') ||
            n.contains('anthropic') ||
            n.contains('gemini'),
      ),
      isFalse,
      reason: 'Vendor SDK adapters belong in services/ai_proxy, not Flutter',
    );

    for (final file in aiDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final content = file.readAsStringSync();
      expect(
        content.contains("import 'package:openai") ||
            content.contains('import "package:openai') ||
            content.contains("import 'package:dart_openai"),
        isFalse,
        reason: file.path,
      );
    }
  });
}
