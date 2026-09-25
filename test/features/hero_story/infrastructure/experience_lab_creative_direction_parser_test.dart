import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/playback/story_experience_demo_stem.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/creative_direction_response_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validDirection() => {
        'narrationEmphasis': 'Emphasize the grounded core message.',
        'pacingGuidance': 'Measured pacing with a pause before the turning point.',
        'pauses': ['Brief pause before turning point'],
        'intensityProgression': [
          {
            'purpose': 'opening',
            'intensity': 'quiet',
            'guidance': 'Restrained opening',
          },
          {
            'purpose': 'challenge',
            'intensity': 'tension',
            'guidance': 'Gradual tension',
          },
          {
            'purpose': 'decision',
            'intensity': 'build',
            'guidance': 'Hopeful build',
          },
          {
            'purpose': 'closing',
            'intensity': 'resolve',
            'guidance': 'Warm resolved ending',
          },
        ],
        'musicPromptBrief':
            'instrumental cinematic acoustic underscore, hopeful mood, '
            'no vocals, no lyrics',
        'transitionNotes': ['Duck music under speech'],
        'providerLabel': 'openai_via_eh_proxy',
        'modelLabel': 'gpt-4o-mini',
        'processingVersion': 'exp-a.creative.v1',
      };

  test('accepts valid structured creative-direction response', () {
    final direction = CreativeDirectionResponseParser.parse(
      jsonEncode(validDirection()),
    );

    expect(direction.narrationEmphasis, contains('grounded core message'));
    expect(direction.pacingGuidance, isNotEmpty);
    expect(direction.musicPromptBrief.toLowerCase(), contains('instrumental'));
    expect(direction.intensityProgression, hasLength(4));
    expect(
      direction.intensityProgression.first.purpose,
      StoryExperiencePresentationPurpose.opening,
    );
    expect(
      direction.intensityProgression.first.intensity,
      MusicIntensityLabel.quiet,
    );
    expect(direction.providerLabel, 'openai_via_eh_proxy');
    expect(
      direction.processingVersion,
      PresentationCreativeDirection.defaultProcessingVersion,
    );
  });

  test('rejects malformed response', () {
    expect(
      () => CreativeDirectionResponseParser.parse('{not-json'),
      throwsA(isA<CreativeDirectionException>()),
    );
    expect(
      () => CreativeDirectionResponseParser.parse('[]'),
      throwsA(isA<CreativeDirectionException>()),
    );
    expect(
      () => CreativeDirectionResponseParser.parse(
        jsonEncode({'narrationEmphasis': 'only this'}),
      ),
      throwsA(isA<CreativeDirectionException>()),
    );
  });

  test('rejects prohibited psychological fields', () {
    for (final key in [
      'personality',
      'trauma',
      'attachmentStyle',
      'resilienceScore',
      'psychologicalProfile',
      'inferredMotivation',
    ]) {
      final bad = validDirection();
      bad[key] = 'forbidden';
      expect(
        () => CreativeDirectionResponseParser.parse(jsonEncode(bad)),
        throwsA(
          isA<CreativeDirectionException>().having(
            (e) => e.message,
            'message',
            contains(key),
          ),
        ),
        reason: 'expected rejection for forbidden field "$key"',
      );
    }
  });

  test('rejects forbidden fields nested in intensityProgression', () {
    final bad = validDirection();
    bad['intensityProgression'] = [
      {
        'purpose': 'opening',
        'intensity': 'quiet',
        'personality': 'anxious',
      },
    ];
    expect(
      () => CreativeDirectionResponseParser.parse(jsonEncode(bad)),
      throwsA(
        isA<CreativeDirectionException>().having(
          (e) => e.message,
          'message',
          contains('personality'),
        ),
      ),
    );
  });
}
