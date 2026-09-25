import 'dart:convert';
import 'dart:typed_data';

import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/music_generation_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_music_generation_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/music_generation_response_parser.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_music_generation_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  MusicGenerationRequest sampleRequest({
    String prompt =
        'instrumental cinematic acoustic underscore, hopeful mood, '
        'no vocals, no lyrics',
    bool instrumentalPreferred = true,
  }) {
    return MusicGenerationRequest(
      storyId: StoryId('story-1'),
      experiencePlanId: StoryExperiencePlanId('plan-1'),
      experiencePlanProcessingVersion: 'hs12.4.v1',
      prompt: prompt,
      targetDurationSeconds: 90,
      mood: 'hopeful',
      energy: 'steady',
      style: 'acoustic',
      instrumentalPreferred: instrumentalPreferred,
      intensityCurveHints: const ['opening:quiet', 'decision:build'],
      processingVersion: MusicRendering.defaultProcessingVersion,
      providerHint: 'stable_audio',
      modelHint: 'stable-audio-3',
      experimentId: 'lab-run-1',
    );
  }

  group('InMemoryMusicGenerationAdapter', () {
    test('maps request fields into a draft with instrumental constraint',
        () async {
      final adapter = InMemoryMusicGenerationAdapter(
        audioBytes: Uint8List.fromList(utf8.encode('fake-music-bytes')),
      );
      final request = sampleRequest();

      final draft = await adapter.generate(request);

      expect(adapter.callCount, 1);
      expect(adapter.lastRequest, same(request));
      expect(adapter.lastRequest!.instrumentalPreferred, isTrue);
      expect(
        adapter.lastRequest!.prompt.toLowerCase(),
        allOf(contains('instrumental'), contains('no vocals')),
      );
      expect(draft.audioBytes, isNotEmpty);
      expect(draft.contentType, 'audio/mpeg');
      expect(draft.instrumental, isTrue);
      expect(draft.duration, const Duration(seconds: 90));
      expect(draft.promptUsed, request.prompt);
      expect(draft.providerLabel, 'in_memory_music_generation');
      expect(draft.modelLabel, 'fake-stable-audio');
      expect(draft.generationId, 'fake-gen-story-1');
      expect(draft.processingVersion, MusicRendering.defaultProcessingVersion);
    });

    test('rejects prompt missing instrumental constraint', () async {
      final adapter = InMemoryMusicGenerationAdapter();
      expect(
        () => adapter.generate(
          sampleRequest(prompt: 'cinematic hopeful underscore'),
        ),
        throwsA(
          isA<MusicGenerationException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('instrumental'),
          ),
        ),
      );
    });

    test('surfaces configured failure', () async {
      final adapter = InMemoryMusicGenerationAdapter(
        failWith: const MusicGenerationException(
          'Music generation proxy failed (502): provider down',
        ),
      );

      expect(
        () => adapter.generate(sampleRequest()),
        throwsA(
          isA<MusicGenerationException>().having(
            (e) => e.message,
            'message',
            contains('502'),
          ),
        ),
      );
      expect(adapter.callCount, 1);
    });
  });

  group('ProxyMusicGenerationAdapter', () {
    test('maps successful proxy response', () async {
      late http.Request captured;
      final audioB64 = base64Encode(utf8.encode('proxy-music-bytes'));
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'audioBase64': audioB64,
            'contentType': 'audio/mpeg',
            'durationSeconds': 88,
            'providerLabel': 'stable_audio_via_eh_proxy',
            'modelLabel': 'stable-audio-3',
            'generationId': 'gen-abc',
            'promptUsed': sampleRequest().prompt,
            'instrumental': true,
            'processingVersion': MusicRendering.defaultProcessingVersion,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final adapter = ProxyMusicGenerationAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
        authToken: 'token',
      );
      final draft = await adapter.generate(sampleRequest());

      expect(captured.url.path, '/story-music-generations');
      expect(captured.headers['authorization'], 'Bearer token');
      final body = jsonDecode(captured.body) as Map;
      expect(body['storyId'], 'story-1');
      expect(body['instrumentalPreferred'], isTrue);
      expect(body['prompt'], contains('instrumental'));
      expect(draft.contentType, 'audio/mpeg');
      expect(draft.instrumental, isTrue);
      expect(draft.providerLabel, 'stable_audio_via_eh_proxy');
      expect(draft.generationId, 'gen-abc');
      expect(utf8.decode(draft.audioBytes), 'proxy-music-bytes');
    });

    test('surfaces provider failure', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'boom'}), 502);
      });
      final adapter = ProxyMusicGenerationAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
      );

      expect(
        () => adapter.generate(sampleRequest()),
        throwsA(
          isA<MusicGenerationException>().having(
            (e) => e.message,
            'message',
            contains('502'),
          ),
        ),
      );
    });
  });

  group('MusicGenerationResponseParser', () {
    test('parses valid response', () {
      final audioB64 = base64Encode(utf8.encode('parsed-music'));
      final draft = MusicGenerationResponseParser.parse(
        jsonEncode({
          'audioBase64': audioB64,
          'contentType': 'audio/wav',
          'durationSeconds': 42,
          'providerLabel': 'proxy',
          'instrumental': true,
        }),
      );
      expect(utf8.decode(draft.audioBytes), 'parsed-music');
      expect(draft.contentType, 'audio/wav');
      expect(draft.duration, const Duration(seconds: 42));
      expect(draft.instrumental, isTrue);
    });

    test('rejects malformed JSON and empty audio', () {
      expect(
        () => MusicGenerationResponseParser.parse('{not-json'),
        throwsA(isA<MusicGenerationException>()),
      );
      expect(
        () => MusicGenerationResponseParser.parse(
          jsonEncode({'audioBase64': '!!!', 'contentType': 'audio/mpeg'}),
        ),
        throwsA(isA<MusicGenerationException>()),
      );
      expect(
        () => MusicGenerationResponseParser.parse(
          jsonEncode({
            'audioBase64': base64Encode(const []),
            'contentType': 'audio/mpeg',
          }),
        ),
        throwsA(isA<MusicGenerationException>()),
      );
    });
  });
}
