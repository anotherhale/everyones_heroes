import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SB.10 Deterministic Story Shaping must remain AI-independent.
void main() {
  test('deterministic story shaper has no AI or network imports', () {
    final source = File(
      'lib/features/hero_story/domain/services/'
      'deterministic_story_shaper.dart',
    ).readAsStringSync();
    expect(source.toLowerCase(), isNot(contains('openai')));
    expect(source.toLowerCase(), isNot(contains('anthropic')));
    expect(source, isNot(contains('StoryBuilderCoachPort')));
    expect(source, isNot(contains('StoryBuilderUnderstandingPort')));
    expect(source, isNot(contains('http')));
    expect(source, isNot(contains('ai_proxy')));
    expect(source, isNot(contains('package:http')));
  });

  test('story shaper port and use case have no AI provider coupling', () {
    for (final path in [
      'lib/features/hero_story/domain/services/story_shaper_port.dart',
      'lib/features/hero_story/application/use_cases/'
          'shape_story_proposal_use_case.dart',
      'lib/features/hero_story/domain/services/deterministic_story_shaper.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source.toLowerCase(), isNot(contains('openai')), reason: path);
      expect(source.toLowerCase(), isNot(contains('anthropic')), reason: path);
      expect(source, isNot(contains('ProxyStoryBuilder')), reason: path);
      expect(source, isNot(contains('ProxyStoryShaperAdapter')), reason: path);
      // Use case may resolve StoryShaperPort strategies; it must not import
      // AI provider SDKs or the proxy adapter.
    }
  });
}
