import 'dart:convert';

import 'package:ai_proxy/ai_proxy.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('ProxyConfig Stability settings', () {
    test('defaults Stability base URL and model when unset', () {
      final config = ProxyConfig.fromEnvironment(
        environment: {'OPENAI_API_KEY': 'k'},
      );
      expect(config.stabilityApiKey, isEmpty);
      expect(config.hasStabilityApiKey, isFalse);
      expect(config.stabilityBaseUrl, 'https://api.stability.ai');
      expect(config.stabilityAudioModel, 'stable-audio-3');
    });

    test('reads Stability env overrides', () {
      final config = ProxyConfig.fromEnvironment(
        environment: {
          'OPENAI_API_KEY': 'k',
          'STABILITY_API_KEY': 'stab-key',
          'STABILITY_BASE_URL': 'https://stability.example',
          'STABILITY_AUDIO_MODEL': 'stable-audio-3',
        },
      );
      expect(config.stabilityApiKey, 'stab-key');
      expect(config.hasStabilityApiKey, isTrue);
      expect(config.stabilityBaseUrl, 'https://stability.example');
      expect(config.stabilityAudioModel, 'stable-audio-3');
    });
  });

  group('ExperienceCreativeDirectionHandler', () {
    late ExperienceCreativeDirectionHandler handler;
    late _FakeChatClient chat;

    Map<String, dynamic> validDirection() => {
          'narrationEmphasis': 'Emphasize the core grounded message.',
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
              'intensity': 'quiet',
            },
            {
              'purpose': 'resolution',
              'intensity': 'expansive',
              'guidance': 'Expansive close',
            },
          ],
          'musicPromptBrief':
              'instrumental acoustic underscore, hopeful, no vocals, no lyrics',
          'transitionNotes': ['Duck music under speech'],
        };

    Map<String, dynamic> requestBody() => {
          'storyId': 's1',
          'experiencePlanId': 'plan-1',
          'experiencePlanProcessingVersion': 'hs12.4.v1',
          'intention': 'inspire',
          'coreMessage': 'Step forward through uncertainty.',
          'emotionalArc': 'perseverance',
          'musicDirection': {
            'mood': 'hopeful',
            'energy': 'steady',
            'style': 'acoustic',
            'rationale': 'Supports movement from challenge to action.',
          },
          'keyMomentLabels': ['Unsure at first', 'Step forward'],
          'sequenceStepTypes': ['story', 'keyMoment', 'music', 'reflection'],
          'reflectionPrompt': 'Where are you being asked to step forward?',
          'targetDurationSeconds': 90,
          'processingVersion': 'exp-a.creative.v1',
        };

    setUp(() {
      chat = _FakeChatClient();
      handler = ExperienceCreativeDirectionHandler(
        config: const ProxyConfig(
          openAiApiKey: 'test-key',
          authToken: 'secret',
        ),
        client: chat,
      );
    });

    test('rejects unauthorized requests when auth token configured', () async {
      final middleware = handler.authMiddleware;
      final inner = middleware((request) async => Response.ok('ok'));
      final response = await inner(
        Request(
          'POST',
          Uri.parse('http://localhost/experience-creative-directions'),
        ),
      );
      expect(response.statusCode, 401);
    });

    test('returns structured creative direction for valid request', () async {
      chat.content = jsonEncode(validDirection());
      final response = await handler.handleDirect(
        Request(
          'POST',
          Uri.parse('http://localhost/experience-creative-directions'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 200);
      final json =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(json['narrationEmphasis'], contains('grounded'));
      expect(json['pacingGuidance'], isNotEmpty);
      expect(json['intensityProgression'], isA<List>());
      expect(json['musicPromptBrief'], contains('instrumental'));
      expect(json['providerLabel'], 'openai_via_eh_proxy');
      expect(json['modelLabel'], 'gpt-4o-mini');
      expect(json['processingVersion'], 'exp-a.creative.v1');
      expect(json['storyId'], 's1');
      expect(chat.lastSystemPrompt, contains('Do NOT diagnose'));
      expect(chat.lastUserPrompt, contains('---BEGIN_MUSIC_DIRECTION---'));
    });

    test('rejects malformed model output', () async {
      chat.content = jsonEncode({
        'narrationEmphasis': 'ok',
        // missing pacingGuidance / intensityProgression / musicPromptBrief
      });
      final response = await handler.handleDirect(
        Request(
          'POST',
          Uri.parse('http://localhost/experience-creative-directions'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['error'], contains('Malformed'));
    });

    test('rejects invalid intensity enum without silent repair', () async {
      final bad = validDirection();
      bad['intensityProgression'] = [
        {'purpose': 'opening', 'intensity': 'epicClimax'},
      ];
      chat.content = jsonEncode(bad);
      final response = await handler.handleDirect(
        Request(
          'POST',
          Uri.parse('http://localhost/experience-creative-directions'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects psychological claim fields', () async {
      final bad = validDirection();
      bad['traumaLevel'] = 'high';
      chat.content = jsonEncode(bad);
      final response = await handler.handleDirect(
        Request(
          'POST',
          Uri.parse('http://localhost/experience-creative-directions'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['error'], contains('forbidden psychological'));
    });

    test('rejects musicPromptBrief without instrumental constraint', () async {
      final bad = validDirection();
      bad['musicPromptBrief'] = 'epic orchestral soundtrack with choir';
      chat.content = jsonEncode(bad);
      final response = await handler.handleDirect(
        Request(
          'POST',
          Uri.parse('http://localhost/experience-creative-directions'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('maps missing required request fields to 400', () async {
      final body = requestBody()..remove('coreMessage');
      final response = await handler.handleDirect(
        Request(
          'POST',
          Uri.parse('http://localhost/experience-creative-directions'),
          body: jsonEncode(body),
        ),
      );
      expect(response.statusCode, 400);
    });

    test('maps provider failure to 502', () async {
      chat.throwOnCall = true;
      final response = await handler.handleDirect(
        Request(
          'POST',
          Uri.parse('http://localhost/experience-creative-directions'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });
  });

  group('ExperienceCreativeDirectionInstructions', () {
    test('prompt invariants', () {
      const prompt = ExperienceCreativeDirectionInstructions.systemPrompt;
      expect(
        ExperienceCreativeDirectionInstructions.prohibitsPsychologicalClaims(
          prompt,
        ),
        isTrue,
      );
      expect(
        ExperienceCreativeDirectionInstructions.requiresInstrumentalMusicBrief(
          prompt,
        ),
        isTrue,
      );
      expect(
        ExperienceCreativeDirectionInstructions.usesClosedVocabularies(prompt),
        isTrue,
      );
    });
  });

  group('StoryMusicGenerationHandler', () {
    late StoryMusicGenerationHandler handler;
    late _FakeStableAudioClient audio;

    Map<String, dynamic> requestBody({
      String prompt =
          'instrumental acoustic underscore, hopeful mood, no vocals',
      bool instrumentalPreferred = true,
      int duration = 60,
    }) {
      return {
        'storyId': 's1',
        'experiencePlanId': 'plan-1',
        'experiencePlanProcessingVersion': 'hs12.4.v1',
        'prompt': prompt,
        'targetDurationSeconds': duration,
        'mood': 'hopeful',
        'energy': 'steady',
        'style': 'acoustic',
        'instrumentalPreferred': instrumentalPreferred,
        'intensityCurveHints': ['quiet opening', 'expansive resolve'],
        'processingVersion': 'exp-a.music.v1',
        'experimentId': 'experiment-a',
        'requestId': 'req-1',
      };
    }

    setUp(() {
      audio = _FakeStableAudioClient();
      handler = StoryMusicGenerationHandler(
        config: const ProxyConfig(
          openAiApiKey: 'test-key',
          authToken: 'secret',
        ),
        client: audio,
      );
    });

    test('rejects unauthorized requests when auth token configured', () async {
      final middleware = handler.authMiddleware;
      final inner = middleware((request) async => Response.ok('ok'));
      final response = await inner(
        Request(
          'POST',
          Uri.parse('http://localhost/story-music-generations'),
        ),
      );
      expect(response.statusCode, 401);
    });

    test('enforces instrumental constraint when preferred', () async {
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-music-generations'),
          body: jsonEncode(
            requestBody(prompt: 'epic pop song with catchy lyrics'),
          ),
        ),
      );
      expect(response.statusCode, 400);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['error'], contains('instrumental'));
      expect(audio.callCount, 0);
    });

    test('returns audioBase64 for successful fake generation', () async {
      audio.audioBytes = utf8.encode('fake-stable-audio-mp3');
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-music-generations'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 200);
      final json =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(json['providerLabel'], 'stable_audio_via_eh_proxy');
      expect(json['modelLabel'], 'stable-audio-3');
      expect(json['instrumental'], isTrue);
      expect(json['processingVersion'], 'exp-a.music.v1');
      expect(json['promptUsed'], contains('instrumental'));
      expect(json['durationSeconds'], 60);
      expect(json['generationId'], 'fake-gen-1');
      expect(
        utf8.decode(base64Decode(json['audioBase64'] as String)),
        'fake-stable-audio-mp3',
      );
      expect(audio.lastPrompt, contains('instrumental'));
      expect(audio.lastDurationSeconds, 60);
    });

    test('maps provider failure to 502', () async {
      audio.throwOnCall = true;
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-music-generations'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['error'], contains('provider down'));
    });

    test('rejects empty provider audio', () async {
      audio.audioBytes = <int>[];
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-music-generations'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects out-of-range duration', () async {
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-music-generations'),
          body: jsonEncode(requestBody(duration: 999)),
        ),
      );
      expect(response.statusCode, 400);
    });

    test('production client fails clearly when Stability key missing', () async {
      final liveHandler = StoryMusicGenerationHandler(
        config: const ProxyConfig(openAiApiKey: 'test-key'),
      );
      final response = await liveHandler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-music-generations'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['error'], contains('STABILITY_API_KEY'));
    });
  });
}

final class _FakeChatClient extends OpenAiChatClient {
  _FakeChatClient()
      : super(
          apiKey: 'x',
          baseUrl: 'http://example.com',
          model: 'test',
        );

  String content = '{}';
  bool throwOnCall = false;
  String? lastSystemPrompt;
  String? lastUserPrompt;

  @override
  Future<OpenAiChatResult> completeJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    lastSystemPrompt = systemPrompt;
    lastUserPrompt = userPrompt;
    if (throwOnCall) {
      throw const OpenAiChatException('provider down');
    }
    return OpenAiChatResult(content: content);
  }
}

final class _FakeStableAudioClient extends StableAudioClient {
  _FakeStableAudioClient()
      : super(
          apiKey: '',
          baseUrl: 'http://example.com',
          model: 'stable-audio-3',
        );

  List<int> audioBytes = utf8.encode('fake-mp3');
  bool throwOnCall = false;
  int callCount = 0;
  String? lastPrompt;
  int? lastDurationSeconds;

  @override
  Future<StableAudioResult> generate({
    required String prompt,
    required int durationSeconds,
    String outputFormat = 'mp3',
  }) async {
    callCount += 1;
    lastPrompt = prompt;
    lastDurationSeconds = durationSeconds;
    if (throwOnCall) {
      throw const StableAudioException('provider down');
    }
    return StableAudioResult(
      audioBytes: audioBytes,
      contentType: 'audio/mpeg',
      model: 'stable-audio-3',
      generationId: 'fake-gen-1',
      durationSeconds: durationSeconds,
    );
  }
}
