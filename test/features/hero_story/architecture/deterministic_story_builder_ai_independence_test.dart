import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deterministic Story Builder has no AI SDK or HTTP imports', () {
    final forbidden = [
      "import 'package:openai",
      'import "package:openai',
      "import 'package:anthropic",
      "import 'package:http/",
      'import "package:http/',
      'OpenAI',
      'Anthropic',
    ];

    final files = [
      File(
        'lib/features/hero_story/domain/services/deterministic_story_builder_catalog.dart',
      ),
      File(
        'lib/features/hero_story/domain/services/deterministic_story_builder_question_strategy.dart',
      ),
      File(
        'lib/features/hero_story/application/use_cases/advance_story_builder_use_case.dart',
      ),
      File(
        'lib/features/hero_story/presentation/providers/story_builder_controller.dart',
      ),
      File(
        'lib/features/hero_story/presentation/screens/story_builder_screen.dart',
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
