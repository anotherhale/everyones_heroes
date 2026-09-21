import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deterministic story structure has no AI SDK or HTTP imports', () {
    final forbidden = [
      "import 'package:openai",
      'import "package:openai',
      "import 'package:anthropic",
      "import 'package:http/",
      'import "package:http/',
      'OpenAI',
      'Anthropic',
      'embedding',
      'Embedding',
    ];

    final files = [
      File(
        'lib/features/hero_story/domain/value_objects/deterministic_story_structure.dart',
      ),
      File(
        'lib/features/hero_story/domain/value_objects/deterministic_story_structure_section.dart',
      ),
      File(
        'lib/features/hero_story/domain/services/deterministic_story_structure_builder.dart',
      ),
      File(
        'lib/features/hero_story/application/use_cases/build_deterministic_story_structure_use_case.dart',
      ),
      File(
        'lib/features/hero_story/application/dto/requests/build_deterministic_story_structure_request.dart',
      ),
    ];

    final offenders = <String>[];
    for (final file in files) {
      expect(file.existsSync(), isTrue, reason: file.path);
      final content = file.readAsStringSync();
      for (final needle in forbidden) {
        if (content.contains(needle)) {
          offenders.add('${file.path} → $needle');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
