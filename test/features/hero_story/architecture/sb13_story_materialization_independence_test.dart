import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SB.13 Story domain stays independent of Story Builder presentation/AI', () {
    final storyDomainFiles = [
      'lib/features/hero_story/domain/aggregates/story.dart',
      'lib/features/hero_story/domain/value_objects/story_provenance.dart',
      'lib/features/hero_story/domain/value_objects/story_narrative.dart',
      'lib/features/hero_story/domain/value_objects/story_title.dart',
      'lib/features/hero_story/domain/repositories/story_repository.dart',
    ];

    final banned = [
      'package:flutter/',
      'package:flutter_riverpod',
      'package:openai',
      'package:anthropic',
      'OpenAI',
      'Anthropic',
      'story_builder_screen',
      'StoryBuilderController',
      'StoryBuilderUiPhase',
      'proxy',
    ];

    for (final path in storyDomainFiles) {
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

  test('SB.13 materialization use case does not import Flutter UI or AI SDKs', () {
    final files = [
      'lib/features/hero_story/application/use_cases/materialize_story_proposal_use_case.dart',
      'lib/features/hero_story/application/mappers/story_materialization_mapper.dart',
    ];

    final banned = [
      'package:flutter/',
      'package:flutter_riverpod',
      'package:openai',
      'package:anthropic',
      'OpenAI',
      'Anthropic',
      'story_builder_screen',
      'StoryBuilderController',
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
