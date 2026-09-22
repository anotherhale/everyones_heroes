import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SB.12 review domain stays AI-vendor independent', () {
    final files = [
      'lib/features/hero_story/domain/value_objects/story_proposal.dart',
      'lib/features/hero_story/domain/value_objects/story_proposal_review.dart',
      'lib/features/hero_story/domain/value_objects/story_proposal_section.dart',
      'lib/features/hero_story/domain/value_objects/story_proposal_section_edit.dart',
      'lib/features/hero_story/domain/enums/story_proposal_review_decision.dart',
      'lib/features/hero_story/application/use_cases/edit_story_proposal_use_case.dart',
      'lib/features/hero_story/application/use_cases/approve_story_proposal_use_case.dart',
      'lib/features/hero_story/application/use_cases/reject_story_proposal_use_case.dart',
      'lib/features/hero_story/application/use_cases/begin_story_proposal_revision_use_case.dart',
    ];

    final banned = [
      'package:openai',
      'package:anthropic',
      'OpenAI',
      'Anthropic',
      'proxy',
      'http://',
      'https://',
      'StoryRepository',
      'CreateStoryUseCase',
      'StoryCreated',
    ];

    for (final path in files) {
      final content = File(path).readAsStringSync();
      for (final token in banned) {
        expect(
          content.contains(token),
          isFalse,
          reason: '$path must not contain "$token"',
        );
      }
    }
  });
}
