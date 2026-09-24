import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_experience_plan_response_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const transcript =
      'I was unsure at first. The challenge was hard. '
      'Then I knew I had to step forward. And that is what I did.';

  Map<String, dynamic> validPlan() => {
        'intention': 'inspire',
        'coreMessage': 'Step forward through uncertainty.',
        'emotionalArc': 'perseverance',
        'keyMoments': [
          {
            'id': 'km-1',
            'description': 'Unsure at first',
            'sourceSpan': {'startOffset': 0, 'endOffset': 22},
          },
        ],
        'musicDirection': {
          'mood': 'hopeful',
          'energy': 'steady',
          'style': 'acoustic',
          'rationale': 'Supports the movement from challenge to action.',
        },
        'reflectionPrompt': 'Where are you being asked to step forward?',
        'sequence': [
          {'type': 'story'},
          {'type': 'keyMoment', 'referenceId': 'km-1'},
          {'type': 'reflection'},
        ],
      };

  test('parses valid response', () {
    final draft = StoryExperiencePlanResponseParser.parse(
      jsonEncode(validPlan()),
      transcriptText: transcript,
      storyId: 's1',
    );
    expect(draft.intention, StoryExperienceIntention.inspire);
    expect(draft.keyMoments, hasLength(1));
    expect(draft.sequence, hasLength(3));
  });

  test('rejects malformed JSON', () {
    expect(
      () => StoryExperiencePlanResponseParser.parse(
        'not-json',
        transcriptText: transcript,
        storyId: 's1',
      ),
      throwsA(isA<StoryExperiencePlannerException>()),
    );
  });

  test('rejects invalid enum', () {
    final bad = validPlan();
    bad['emotionalArc'] = 'traumaRecovery';
    expect(
      () => StoryExperiencePlanResponseParser.parse(
        jsonEncode(bad),
        transcriptText: transcript,
        storyId: 's1',
      ),
      throwsA(isA<StoryExperiencePlannerException>()),
    );
  });

  test('rejects out-of-range offsets', () {
    final bad = validPlan();
    bad['keyMoments'] = [
      {
        'id': 'km-1',
        'description': 'bad',
        'sourceSpan': {'startOffset': 0, 'endOffset': 9999},
      },
    ];
    expect(
      () => StoryExperiencePlanResponseParser.parse(
        jsonEncode(bad),
        transcriptText: transcript,
        storyId: 's1',
      ),
      throwsA(isA<StoryExperiencePlannerException>()),
    );
  });

  test('rejects psychological claim fields', () {
    final bad = validPlan();
    bad['resilienceScore'] = 9;
    expect(
      () => StoryExperiencePlanResponseParser.parse(
        jsonEncode(bad),
        transcriptText: transcript,
        storyId: 's1',
      ),
      throwsA(isA<StoryExperiencePlannerException>()),
    );
  });
}
