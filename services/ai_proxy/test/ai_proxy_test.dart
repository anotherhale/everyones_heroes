import 'dart:convert';

import 'package:ai_proxy/ai_proxy.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('StoryTranscriptionHandler', () {
    late StoryTranscriptionHandler handler;

    setUp(() {
      handler = StoryTranscriptionHandler(
        config: const ProxyConfig(
          openAiApiKey: 'test-key',
          authToken: 'secret',
        ),
        client: _FakeOpenAiClient(),
      );
    });

    test('rejects unauthorized requests when auth token configured', () async {
      final middleware = handler.authMiddleware;
      final inner = middleware((request) async => Response.ok('ok'));
      final response = await inner(
        Request('POST', Uri.parse('http://localhost/story-transcriptions')),
      );
      expect(response.statusCode, 401);
    });

    test('transcribes valid EH request body', () async {
      final body = jsonEncode({
        'storyId': 's1',
        'sourceRepresentationId': 'r1',
        'language': 'en',
        'processingVersion': 'hs4-v1',
        'requestId': 'req-1',
        'mediaBase64': base64Encode([1, 2, 3, 4]),
        'contentType': 'audio/wav',
      });
      final response = await handler.handleTranscribe(
        Request(
          'POST',
          Uri.parse('http://localhost/story-transcriptions'),
          body: body,
        ),
      );
      expect(response.statusCode, 200);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['text'], 'hello from fake openai');
      expect(json['providerLabel'], 'openai_via_eh_proxy');
    });

    test('maps malformed body to 400', () async {
      final response = await handler.handleTranscribe(
        Request(
          'POST',
          Uri.parse('http://localhost/story-transcriptions'),
          body: 'not-json',
        ),
      );
      expect(response.statusCode, 400);
    });
  });

  group('StoryBuilderCoachHandler', () {
    late StoryBuilderCoachHandler handler;
    late _FakeChatClient chat;

    setUp(() {
      chat = _FakeChatClient();
      handler = StoryBuilderCoachHandler(
        config: const ProxyConfig(
          openAiApiKey: 'test-key',
          authToken: 'secret',
        ),
        client: chat,
      );
    });

    test('returns EH-owned coach suggestion', () async {
      chat.content = jsonEncode({
        'question': 'What was the turning point?',
        'narrativeRole': 'turningPoint',
        'reason': 'gap',
        'readyToComplete': false,
      });
      final body = jsonEncode({
        'purpose': 'inspireSomeone',
        'themes': ['perseverance'],
        'themesUnsure': false,
        'presentedNarrativeRoles': ['beginning'],
        'turns': [
          {
            'promptText': 'Where did it begin?',
            'ordinal': 0,
            'narrativeRole': 'beginning',
            'responseText': 'On a rainy Tuesday I almost quit.',
            'skipped': false,
          },
        ],
      });
      final response = await handler.handleSuggestQuestion(
        Request(
          'POST',
          Uri.parse('http://localhost/story-builder-questions'),
          body: body,
        ),
      );
      expect(response.statusCode, 200);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['question'], 'What was the turning point?');
      expect(json['narrativeRole'], 'turningPoint');
      expect(json['providerLabel'], 'openai_via_eh_proxy');
      expect(chat.lastSystemPrompt, contains('Do not invent facts'));
      expect(chat.lastUserPrompt, contains('---BEGIN_STORY_BUILDER_CONTEXT---'));
      expect(chat.lastUserPrompt, contains('almost quit'));
    });

    test('maps provider failure to 502', () async {
      chat.throwOnCall = true;
      final response = await handler.handleSuggestQuestion(
        Request(
          'POST',
          Uri.parse('http://localhost/story-builder-questions'),
          body: jsonEncode({'turns': []}),
        ),
      );
      expect(response.statusCode, 502);
    });
  });

  group('StoryBuilderCoachInstructions', () {
    test('prompt invariants', () {
      const prompt = StoryBuilderCoachInstructions.systemPrompt;
      expect(StoryBuilderCoachInstructions.mentionsOneQuestionConstraint(prompt), isTrue);
      expect(StoryBuilderCoachInstructions.prohibitsInvention(prompt), isTrue);
      expect(StoryBuilderCoachInstructions.prohibitsWritingStory(prompt), isTrue);
      expect(StoryBuilderCoachInstructions.mentionsNarrativeRoles(prompt), isTrue);
    });
  });

  group('StoryUnderstandingHandler', () {
    late StoryUnderstandingHandler handler;
    late _FakeChatClient chat;

    setUp(() {
      chat = _FakeChatClient();
      handler = StoryUnderstandingHandler(
        config: const ProxyConfig(
          openAiApiKey: 'test-key',
          authToken: 'secret',
        ),
        client: chat,
      );
    });

    test('returns EH-owned understanding payload', () async {
      chat.content = jsonEncode({
        'themes': [
          {
            'theme': 'perseverance',
            'sourceResponseIds': ['r1'],
          },
        ],
        'narrativeElements': [
          {
            'narrativeRole': 'challenge',
            'sourceResponseIds': ['r1'],
            'derivedNote': 'Hero described a challenge.',
          },
        ],
        'keyElements': {
          'challenge': {
            'sourceResponseIds': ['r1'],
            'derivedInterpretation': 'A challenge was stated.',
          },
        },
        'significantEvents': [],
        'derivedSummary': 'Short derived analysis.',
      });
      final body = jsonEncode({
        'purpose': 'inspireSomeone',
        'themes': ['perseverance'],
        'themesUnsure': false,
        'structureSections': [
          {
            'narrativeRole': 'challenge',
            'order': 1,
            'sourceResponseIds': ['r1'],
            'wasSkipped': false,
            'hasSourceMaterial': true,
          },
        ],
        'responses': [
          {
            'id': 'r1',
            'ordinal': 1,
            'narrativeRole': 'challenge',
            'text': 'I struggled for years before things changed.',
            'skipped': false,
          },
        ],
      });
      final response = await handler.handleUnderstand(
        Request(
          'POST',
          Uri.parse('http://localhost/story-understanding'),
          body: body,
        ),
      );
      expect(response.statusCode, 200);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['providerLabel'], 'openai_via_eh_proxy');
      expect(json['themes'], isA<List>());
      expect(chat.lastSystemPrompt, contains('Do not invent facts'));
      expect(chat.lastUserPrompt, contains('---BEGIN_STORY_BUILDER_CONTEXT---'));
      expect(chat.lastUserPrompt, contains('struggled for years'));
    });

    test('maps provider failure to 502', () async {
      chat.throwOnCall = true;
      final response = await handler.handleUnderstand(
        Request(
          'POST',
          Uri.parse('http://localhost/story-understanding'),
          body: jsonEncode({'responses': []}),
        ),
      );
      expect(response.statusCode, 502);
    });
  });

  group('StoryUnderstandingInstructions', () {
    test('prompt invariants', () {
      const prompt = StoryUnderstandingInstructions.systemPrompt;
      expect(StoryUnderstandingInstructions.prohibitsInvention(prompt), isTrue);
      expect(StoryUnderstandingInstructions.prohibitsWritingStory(prompt), isTrue);
      expect(StoryUnderstandingInstructions.requiresProvenance(prompt), isTrue);
      expect(StoryUnderstandingInstructions.mentionsClosedThemes(prompt), isTrue);
    });
  });

  group('StoryAuthoringHandler', () {
    late StoryAuthoringHandler handler;
    late _FakeChatClient chat;

    setUp(() {
      chat = _FakeChatClient();
      handler = StoryAuthoringHandler(
        config: const ProxyConfig(
          openAiApiKey: 'test-key',
          authToken: 'secret',
        ),
        client: chat,
      );
    });

    test('returns EH-owned authoring payload', () async {
      chat.content = jsonEncode({
        'title': 'Kept Going',
        'summary': 'A short derived summary.',
        'sections': [
          {
            'role': 'struggle',
            'content':
                'Even when giving up felt tempting, the Hero chose to keep moving.',
            'sourceResponseIds': ['r17'],
          },
        ],
        'warnings': [],
        'lifecycle': 'accepted',
        'contentOrigin': 'heroAuthored',
      });
      final body = jsonEncode({
        'purpose': 'inspireSomeone',
        'themes': ['perseverance'],
        'themesUnsure': false,
        'title': null,
        'summary': 'I kept going even when I wanted to quit.',
        'understandingSummary': 'The Hero appears to value perseverance.',
        'sections': [
          {
            'role': 'struggle',
            'content': 'I kept going even when I wanted to quit.',
            'sourceResponseIds': ['r17'],
            'contentOrigin': 'heroAuthored',
            'wasSkipped': false,
          },
        ],
      });
      final response = await handler.handleAuthor(
        Request(
          'POST',
          Uri.parse('http://localhost/story-authoring'),
          body: body,
        ),
      );
      expect(response.statusCode, 200);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['providerLabel'], 'openai_via_eh_proxy');
      expect(json['promptOrTemplateVersion'], 'sb11.ai.v1');
      expect(json['sections'], isA<List>());
      expect(json.containsKey('lifecycle'), isFalse);
      expect(json.containsKey('contentOrigin'), isFalse);
      expect(chat.lastSystemPrompt, contains('factual source of truth'));
      expect(chat.lastUserPrompt, contains('---BEGIN_STORY_AUTHORING_CONTEXT---'));
      expect(chat.lastUserPrompt, contains('wanted to quit'));
      expect(
        chat.lastSystemPrompt,
        contains(StoryAuthoringInstructions.systemPrompt.substring(0, 40)),
      );
    });

    test('rejects malformed request body', () async {
      final response = await handler.handleAuthor(
        Request(
          'POST',
          Uri.parse('http://localhost/story-authoring'),
          body: 'not-json',
        ),
      );
      expect(response.statusCode, 400);
    });

    test('rejects empty sections', () async {
      final response = await handler.handleAuthor(
        Request(
          'POST',
          Uri.parse('http://localhost/story-authoring'),
          body: jsonEncode({'sections': []}),
        ),
      );
      expect(response.statusCode, 400);
    });

    test('maps provider failure to 502', () async {
      chat.throwOnCall = true;
      final response = await handler.handleAuthor(
        Request(
          'POST',
          Uri.parse('http://localhost/story-authoring'),
          body: jsonEncode({
            'sections': [
              {
                'role': 'beginning',
                'content': 'Once',
                'sourceResponseIds': ['r1'],
                'contentOrigin': 'heroAuthored',
                'wasSkipped': false,
              },
            ],
          }),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('maps malformed provider response to 502', () async {
      chat.content = 'not-json';
      final response = await handler.handleAuthor(
        Request(
          'POST',
          Uri.parse('http://localhost/story-authoring'),
          body: jsonEncode({
            'sections': [
              {
                'role': 'beginning',
                'content': 'Once',
                'sourceResponseIds': ['r1'],
                'contentOrigin': 'heroAuthored',
                'wasSkipped': false,
              },
            ],
          }),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('auth middleware rejects missing bearer token', () async {
      final pipeline = const Pipeline()
          .addMiddleware(handler.authMiddleware)
          .addHandler(handler.router.call);
      final response = await pipeline(
        Request(
          'POST',
          Uri.parse('http://localhost/story-authoring'),
          body: jsonEncode({
            'sections': [
              {
                'role': 'beginning',
                'content': 'Once',
                'sourceResponseIds': ['r1'],
                'contentOrigin': 'heroAuthored',
                'wasSkipped': false,
              },
            ],
          }),
        ),
      );
      expect(response.statusCode, 401);
    });
  });

  group('StoryAuthoringInstructions', () {
    test('prompt invariants', () {
      const prompt = StoryAuthoringInstructions.systemPrompt;
      expect(StoryAuthoringInstructions.requiresSourceFidelity(prompt), isTrue);
      expect(StoryAuthoringInstructions.prohibitsInvention(prompt), isTrue);
      expect(StoryAuthoringInstructions.requiresProvenance(prompt), isTrue);
      expect(StoryAuthoringInstructions.distinguishesDerived(prompt), isTrue);
      expect(StoryAuthoringInstructions.preservesUncertainty(prompt), isTrue);
      expect(StoryAuthoringInstructions.preservesVoice(prompt), isTrue);
      expect(prompt.contains('Manufacture quotes'), isTrue);
    });
  });

  group('CapturedStoryReadingHandler', () {
    late CapturedStoryReadingHandler handler;
    late _FakeChatClient chat;

    const transcript =
        'I was unsure at first. The challenge was hard. '
        'Then I knew I had to step forward. And that is what I did.';

    Map<String, dynamic> validReading() => {
          'movement': {
            'text': 'The story shifts from uncertainty to action.',
            'sourceSpan': {'startOffset': 0, 'endOffset': 22},
          },
          'themes': [
            {
              'label': 'courage',
              'sourceSpan': {'startOffset': 0, 'endOffset': 10},
            },
          ],
          'challenge': {
            'text': 'The challenge was hard.',
            'sourceSpan': {'startOffset': 23, 'endOffset': 46},
          },
          'turningPoint': {
            'text': 'I knew I had to step forward.',
            'sourceSpan': {'startOffset': 47, 'endOffset': 80},
          },
          'outcome': {
            'text': 'And that is what I did.',
            'sourceSpan': {'startOffset': 81, 'endOffset': transcript.length},
          },
        };

    setUp(() {
      chat = _FakeChatClient();
      handler = CapturedStoryReadingHandler(
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
          Uri.parse('http://localhost/captured-story-readings'),
        ),
      );
      expect(response.statusCode, 401);
    });

    test('returns grounded reading for valid request', () async {
      chat.content = jsonEncode(validReading());
      final body = jsonEncode({
        'storyId': 's1',
        'transcriptRepresentationId': 't1',
        'transcriptText': transcript,
        'language': 'en',
        'processingVersion': 'hs12.3.v1',
      });
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/captured-story-readings'),
          body: body,
        ),
      );
      expect(response.statusCode, 200);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['movement'], isA<Map>());
      expect(json['themes'], isA<List>());
      expect(json['challenge'], isA<Map>());
      expect(json['turningPoint'], isA<Map>());
      expect(json['outcome'], isA<Map>());
      expect(json['providerLabel'], 'openai_via_eh_proxy');
      expect(json['storyId'], 's1');
      expect(chat.lastSystemPrompt, contains('Do NOT diagnose'));
      expect(chat.lastUserPrompt, contains('---BEGIN_TRANSCRIPT---'));
      expect(chat.lastUserPrompt, contains('step forward'));
    });

    test('maps malformed body to 400', () async {
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/captured-story-readings'),
          body: 'not-json',
        ),
      );
      expect(response.statusCode, 400);
    });

    test('maps missing transcript to 400', () async {
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/captured-story-readings'),
          body: jsonEncode({
            'storyId': 's1',
            'transcriptRepresentationId': 't1',
          }),
        ),
      );
      expect(response.statusCode, 400);
    });

    test('maps provider failure to 502', () async {
      chat.throwOnCall = true;
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/captured-story-readings'),
          body: jsonEncode({
            'storyId': 's1',
            'transcriptRepresentationId': 't1',
            'transcriptText': transcript,
          }),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects invalid AI response missing grounded fields', () async {
      chat.content = jsonEncode({
        'movement': {
          'text': 'ok',
          'sourceSpan': {'startOffset': 0, 'endOffset': 2},
        },
        'themes': [
          {
            'label': 'courage',
            'sourceSpan': {'startOffset': 0, 'endOffset': 2},
          },
        ],
        // missing challenge / turningPoint / outcome
      });
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/captured-story-readings'),
          body: jsonEncode({
            'storyId': 's1',
            'transcriptRepresentationId': 't1',
            'transcriptText': transcript,
          }),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects spans outside transcript', () async {
      final bad = validReading();
      bad['challenge'] = {
        'text': 'out of range',
        'sourceSpan': {'startOffset': 0, 'endOffset': 9999},
      };
      chat.content = jsonEncode(bad);
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/captured-story-readings'),
          body: jsonEncode({
            'storyId': 's1',
            'transcriptRepresentationId': 't1',
            'transcriptText': transcript,
          }),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects psychological claim fields', () async {
      final bad = validReading();
      bad['personality'] = 'resilient';
      chat.content = jsonEncode(bad);
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/captured-story-readings'),
          body: jsonEncode({
            'storyId': 's1',
            'transcriptRepresentationId': 't1',
            'transcriptText': transcript,
          }),
        ),
      );
      expect(response.statusCode, 502);
    });
  });

  group('CapturedStoryReadingInstructions', () {
    test('prompt invariants', () {
      const prompt = CapturedStoryReadingInstructions.systemPrompt;
      expect(
        CapturedStoryReadingInstructions.prohibitsPsychologicalClaims(prompt),
        isTrue,
      );
      expect(
        CapturedStoryReadingInstructions.requiresSourceSpans(prompt),
        isTrue,
      );
      expect(
        CapturedStoryReadingInstructions.prohibitsRewritingStory(prompt),
        isTrue,
      );
    });
  });

  group('StoryExperiencePlanHandler', () {
    late StoryExperiencePlanHandler handler;
    late _FakeChatClient chat;

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
            {
              'id': 'km-2',
              'description': 'Step forward',
              'sourceSpan': {'startOffset': 47, 'endOffset': 80},
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
            {'type': 'keyMoment', 'referenceId': 'km-2'},
            {'type': 'music'},
            {'type': 'reflection'},
          ],
        };

    Map<String, dynamic> requestBody() => {
          'storyId': 's1',
          'transcriptRepresentationId': 't1',
          'transcriptText': transcript,
          'processingVersion': 'hs12.4.v1',
          'reading': {
            'movement': {'text': 'Uncertainty to action'},
          },
        };

    setUp(() {
      chat = _FakeChatClient();
      handler = StoryExperiencePlanHandler(
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
          Uri.parse('http://localhost/story-experience-plans'),
        ),
      );
      expect(response.statusCode, 401);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['error'], 'unauthorized');
    });

    test('returns typed plan for valid request', () async {
      chat.content = jsonEncode(validPlan());
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-experience-plans'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 200);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['intention'], 'inspire');
      expect(json['emotionalArc'], 'perseverance');
      expect(json['keyMoments'], isA<List>());
      expect(json['musicDirection'], isA<Map>());
      expect(json['providerLabel'], 'openai_via_eh_proxy');
      expect(json['storyId'], 's1');
      expect(chat.lastSystemPrompt, contains('Do NOT diagnose'));
      expect(chat.lastUserPrompt, contains('---BEGIN_TRANSCRIPT---'));
    });

    test('maps malformed body to 400', () async {
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-experience-plans'),
          body: 'not-json',
        ),
      );
      expect(response.statusCode, 400);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['error'], contains('Malformed'));
    });

    test('maps provider failure to 502', () async {
      chat.throwOnCall = true;
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-experience-plans'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['error'], isNotEmpty);
    });

    test('rejects invalid enum', () async {
      final bad = validPlan();
      bad['intention'] = 'diagnosePersonality';
      chat.content = jsonEncode(bad);
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-experience-plans'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects invalid source span / out-of-range offsets', () async {
      final bad = validPlan();
      bad['keyMoments'] = [
        {
          'id': 'km-1',
          'description': 'out of range',
          'sourceSpan': {'startOffset': 0, 'endOffset': 9999},
        },
      ];
      bad['sequence'] = [
        {'type': 'keyMoment', 'referenceId': 'km-1'},
      ];
      chat.content = jsonEncode(bad);
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-experience-plans'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects unsupported sequence type', () async {
      final bad = validPlan();
      bad['sequence'] = [
        {'type': 'story'},
        {'type': 'aiVoice'},
      ];
      chat.content = jsonEncode(bad);
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-experience-plans'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects psychological claim fields', () async {
      final bad = validPlan();
      bad['traumaLevel'] = 'high';
      chat.content = jsonEncode(bad);
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-experience-plans'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });
  });

  group('StoryExperiencePlanInstructions', () {
    test('prompt invariants', () {
      const prompt = StoryExperiencePlanInstructions.systemPrompt;
      expect(
        StoryExperiencePlanInstructions.prohibitsPsychologicalClaims(prompt),
        isTrue,
      );
      expect(
        StoryExperiencePlanInstructions.requiresSourceSpans(prompt),
        isTrue,
      );
      expect(
        StoryExperiencePlanInstructions.prohibitsAudioGeneration(prompt),
        isTrue,
      );
      expect(
        StoryExperiencePlanInstructions.usesClosedVocabularies(prompt),
        isTrue,
      );
    });
  });

  test('ProxyConfig requires OPENAI_API_KEY', () {
    expect(
      () => ProxyConfig.fromEnvironment(environment: {}),
      throwsStateError,
    );
  });

  test('ProxyConfig reads chat model', () {
    final config = ProxyConfig.fromEnvironment(
      environment: {
        'OPENAI_API_KEY': 'k',
        'OPENAI_CHAT_MODEL': 'gpt-test',
      },
    );
    expect(config.chatModel, 'gpt-test');
  });

  test('ProxyConfig reads speech model and voice', () {
    final config = ProxyConfig.fromEnvironment(
      environment: {
        'OPENAI_API_KEY': 'k',
        'OPENAI_SPEECH_MODEL': 'tts-1-hd',
        'OPENAI_SPEECH_VOICE': 'nova',
      },
    );
    expect(config.speechModel, 'tts-1-hd');
    expect(config.speechVoice, 'nova');
  });

  group('StoryVoiceRenderingHandler', () {
    late StoryVoiceRenderingHandler handler;
    late _FakeSpeechClient speech;

    Map<String, dynamic> requestBody({
      String mode = 'syntheticNarration',
      String sourceText = 'A grounded hero story transcript.',
    }) {
      return {
        'storyId': 'story-1',
        'experiencePlanId': 'plan-1',
        'experiencePlanProcessingVersion': 'hs12.4.v1',
        'sourceRepresentationId': 'transcript-1',
        'sourceText': sourceText,
        'renderingMode': mode,
        'processingVersion': 'hs12.6.v1',
      };
    }

    setUp(() {
      speech = _FakeSpeechClient();
      handler = StoryVoiceRenderingHandler(
        config: const ProxyConfig(openAiApiKey: 'k', authToken: 'secret'),
        client: speech,
      );
    });

    test('rejects unauthorized requests', () async {
      final middleware = handler.authMiddleware;
      final inner = middleware((request) async => Response.ok('ok'));
      final response = await inner(
        Request(
          'POST',
          Uri.parse('http://localhost/story-voice-renderings'),
        ),
      );
      expect(response.statusCode, 401);
    });

    test('rejects missing sourceText', () async {
      final body = requestBody(sourceText: '  ');
      final response = await handler.handleRender(
        Request(
          'POST',
          Uri.parse('http://localhost/story-voice-renderings'),
          body: jsonEncode(body),
        ),
      );
      expect(response.statusCode, 400);
    });

    test('rejects unsupported renderingMode (voice cloning)', () async {
      final response = await handler.handleRender(
        Request(
          'POST',
          Uri.parse('http://localhost/story-voice-renderings'),
          body: jsonEncode(requestBody(mode: 'voiceClone')),
        ),
      );
      expect(response.statusCode, 400);
      final decoded = jsonDecode(await response.readAsString()) as Map;
      expect(decoded['error'], contains('syntheticNarration'));
      expect(decoded['error'], contains('not voice cloning'));
    });

    test('returns base64 audio for synthetic narration', () async {
      speech.audioBytes = utf8.encode('fake-mp3-bytes');
      final response = await handler.handleRender(
        Request(
          'POST',
          Uri.parse('http://localhost/story-voice-renderings'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 200);
      final decoded =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(decoded['renderingMode'], 'syntheticNarration');
      expect(decoded['contentType'], 'audio/mpeg');
      expect(decoded['providerLabel'], 'openai_tts_via_eh_proxy');
      expect(decoded['processingVersion'], 'hs12.6.v1');
      expect(decoded['audioBase64'], isNotEmpty);
      expect(
        utf8.decode(base64Decode(decoded['audioBase64'] as String)),
        'fake-mp3-bytes',
      );
    });

    test('maps provider failure to 502', () async {
      speech.throwOnCall = true;
      final response = await handler.handleRender(
        Request(
          'POST',
          Uri.parse('http://localhost/story-voice-renderings'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });

    test('rejects empty provider audio', () async {
      speech.audioBytes = <int>[];
      final response = await handler.handleRender(
        Request(
          'POST',
          Uri.parse('http://localhost/story-voice-renderings'),
          body: jsonEncode(requestBody()),
        ),
      );
      expect(response.statusCode, 502);
    });
  });
}

final class _FakeOpenAiClient extends OpenAiTranscriptionClient {
  _FakeOpenAiClient()
      : super(
          apiKey: 'x',
          baseUrl: 'http://example.com',
          model: 'test',
        );

  @override
  Future<OpenAiTranscriptionResult> transcribe({
    required List<int> audioBytes,
    required String contentType,
    required String filename,
    String? language,
  }) async {
    return OpenAiTranscriptionResult(
      text: 'hello from fake openai',
      language: language,
    );
  }
}

final class _FakeChatClient extends OpenAiChatClient {
  _FakeChatClient()
      : super(
          apiKey: 'x',
          baseUrl: 'http://example.com',
          model: 'test',
        );

  String content = '{"question":"Q?","readyToComplete":false}';
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

final class _FakeSpeechClient extends OpenAiSpeechClient {
  _FakeSpeechClient()
      : super(
          apiKey: 'x',
          baseUrl: 'http://example.com',
          model: 'tts-1',
        );

  List<int> audioBytes = utf8.encode('fake-mp3');
  bool throwOnCall = false;

  @override
  Future<OpenAiSpeechResult> synthesize({
    required String text,
    String responseFormat = 'mp3',
  }) async {
    if (throwOnCall) {
      throw const OpenAiSpeechException('provider down');
    }
    return OpenAiSpeechResult(
      audioBytes: audioBytes,
      contentType: 'audio/mpeg',
      model: 'tts-1',
      voice: 'alloy',
    );
  }
}
