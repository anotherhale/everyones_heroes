import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SB.11 keeps domain AI-agnostic: transport details stay in infrastructure.
void main() {
  test('AiStoryShaper domain service has no HTTP/provider imports', () {
    final source = File(
      'lib/features/hero_story/domain/services/ai_story_shaper.dart',
    ).readAsStringSync();
    expect(source.toLowerCase(), isNot(contains('openai')));
    expect(source.toLowerCase(), isNot(contains('anthropic')));
    expect(source, isNot(contains('package:http')));
    expect(source, isNot(contains('ProxyStoryShaperAdapter')));
    expect(source, isNot(contains('ai_proxy')));
  });

  test('StoryShaperPort remains the shaping strategy boundary', () {
    final source = File(
      'lib/features/hero_story/domain/services/story_shaper_port.dart',
    ).readAsStringSync();
    expect(source, contains('StoryShaperPort'));
    expect(source, isNot(contains('AiStoryAuthorPort')));
  });

  test('deterministic SB.10 path remains free of AI authoring imports', () {
    final source = File(
      'lib/features/hero_story/domain/services/'
      'deterministic_story_shaper.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('StoryAuthoringTransport')));
    expect(source, isNot(contains('AiStoryShaper')));
    expect(source, isNot(contains('package:http')));
  });
}
