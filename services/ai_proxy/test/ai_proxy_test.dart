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
