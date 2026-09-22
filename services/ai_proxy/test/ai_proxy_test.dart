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
