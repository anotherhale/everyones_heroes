import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lightweight architecture boundary checks for HS.4 (no AI SDK leakage).
void main() {
  test('domain and application layers do not import AI SDKs', () {
    final forbidden = [
      'package:openai',
      'package:anthropic',
      'package:google_generative_ai',
      'package:dart_openai',
      'package:langchain',
      'bedrock',
      'package:http/http.dart', // domain must stay free of HTTP clients
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
        for (final needle in forbidden) {
          if (content.contains(needle)) {
            // Allow clarifying that HTTP is forbidden in comments only if quoted carefully;
            // fail on actual import lines.
            if (content.contains("import '$needle") ||
                content.contains('import "$needle') ||
                content.contains("import 'package:http") ||
                content.contains('import "package:http')) {
              offenders.add('${entity.path} → $needle');
            }
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
      if (content.contains("import 'package:everyonesheroes/features/discovery")) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no production AI provider adapters exist under infrastructure/ai', () {
    final aiDir = Directory('lib/features/hero_story/infrastructure/ai');
    expect(aiDir.existsSync(), isTrue);
    final names = aiDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
    expect(names, contains('in_memory_story_transcription_adapter.dart'));
    expect(names, contains('in_memory_story_understanding_adapter.dart'));
    expect(
      names.any((n) => n.contains('openai') || n.contains('anthropic') || n.contains('gemini')),
      isFalse,
    );
  });
}
