import 'dart:convert';

import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_provider_config.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/creative_direction_response_parser.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_creative_direction_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  CreativeDirectionRequest sampleRequest({String? modelHint}) {
    return CreativeDirectionRequest(
      storyId: StoryId('story-1'),
      experiencePlanId: StoryExperiencePlanId('plan-1'),
      experiencePlanProcessingVersion: 'hs12.4.v1',
      intention: StoryExperienceIntention.inspire,
      coreMessage: 'Step forward through uncertainty.',
      emotionalArc: StoryExperienceArc.perseverance,
      musicDirection: StoryExperienceMusicDirection(
        mood: 'hopeful',
        energy: 'steady',
        style: 'acoustic',
        rationale: 'Supports movement from challenge to action.',
      ),
      keyMomentLabels: const ['Unsure at first', 'Step forward'],
      sequenceStepTypes: const ['story', 'keyMoment', 'music', 'reflection'],
      reflectionPrompt: 'Where are you being asked to step forward?',
      targetDurationSeconds: 90,
      providerHint: 'openai',
      modelHint: modelHint,
    );
  }

  Map<String, dynamic> validProxyResponse({
    String modelLabel = 'gpt-5.6-luna',
  }) =>
      {
        'narrationEmphasis': 'Emphasize the grounded core message.',
        'pacingGuidance': 'Measured pacing with a pause before the turn.',
        'pauses': ['Brief pause before turning point'],
        'intensityProgression': [
          {
            'purpose': 'opening',
            'intensity': 'quiet',
            'guidance': 'Restrained opening',
          },
          {
            'purpose': 'turningPoint',
            'intensity': 'build',
          },
          {
            'purpose': 'resolution',
            'intensity': 'expansive',
          },
        ],
        'musicPromptBrief':
            'instrumental acoustic underscore, hopeful, no vocals, no lyrics',
        'transitionNotes': ['Duck music under speech'],
        'storyId': 'story-1',
        'experiencePlanId': 'plan-1',
        'experiencePlanProcessingVersion': 'hs12.4.v1',
        'providerLabel': 'openai_via_eh_proxy',
        'modelLabel': modelLabel,
        'processingVersion': 'exp-a.creative.v1',
      };

  group('ExperienceLabProviderConfig.experimentA', () {
    test('does not hard-code a vendor chat model as creativeModel', () {
      final config = ExperienceLabProviderConfig.experimentA();
      expect(config.creativeModel, 'eh-proxy-chat');
      expect(config.creativeModel, isNot('gpt-4o-mini'));
      expect(config.creativeModel, isNot(contains('gpt-5')));
    });
  });

  group('ProxyCreativeDirectionAdapter', () {
    test('does not send Flutter modelHint; keeps proxy modelLabel', () async {
      late Map<String, dynamic> sentBody;
      final adapter = ProxyCreativeDirectionAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(validProxyResponse(modelLabel: 'gpt-5.6-luna')),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(adapter.dispose);

      final direction = await adapter.direct(
        sampleRequest(modelHint: 'gpt-4o-mini'),
      );

      expect(sentBody.containsKey('model'), isFalse);
      expect(direction.modelLabel, 'gpt-5.6-luna');
      expect(direction.providerLabel, 'openai_via_eh_proxy');
    });
  });

  group('CreativeDirectionResponseParser modelLabel', () {
    test('preserves proxy-authoritative modelLabel from response', () {
      final direction = CreativeDirectionResponseParser.parse(
        jsonEncode(validProxyResponse(modelLabel: 'gpt-5.6-luna')),
      );
      expect(direction.modelLabel, 'gpt-5.6-luna');
    });
  });
}
