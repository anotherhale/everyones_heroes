import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SB.9 Story Proposal domain must remain AI-independent.
void main() {
  test('deterministic story proposal builder has no AI imports', () {
    final source = File(
      'lib/features/hero_story/domain/services/'
      'deterministic_story_proposal_builder.dart',
    ).readAsStringSync();
    expect(source.toLowerCase(), isNot(contains('openai')));
    expect(source.toLowerCase(), isNot(contains('anthropic')));
    expect(source, isNot(contains('StoryBuilderCoachPort')));
    expect(source, isNot(contains('StoryBuilderUnderstandingPort')));
    expect(source, isNot(contains('http')));
    expect(source, isNot(contains('ai_proxy')));
  });

  test('story proposal value objects have no AI imports', () {
    for (final path in [
      'lib/features/hero_story/domain/value_objects/story_proposal.dart',
      'lib/features/hero_story/domain/value_objects/story_proposal_section.dart',
      'lib/features/hero_story/domain/value_objects/story_proposal_provenance.dart',
      'lib/features/hero_story/application/use_cases/build_story_proposal_use_case.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source.toLowerCase(), isNot(contains('openai')), reason: path);
      expect(source, isNot(contains('StoryBuilderUnderstandingPort')),
          reason: path);
      expect(source, isNot(contains('ProxyStoryBuilder')), reason: path);
    }
  });
}
