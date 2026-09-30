import 'dart:convert';

import 'package:ai_proxy/ai_proxy.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('StoryBuilderScriptHandler', () {
    late StoryBuilderScriptHandler handler;
    late _FakeChatClient chat;

    setUp(() {
      chat = _FakeChatClient();
      handler = StoryBuilderScriptHandler(
        config: const ProxyConfig(
          openAiApiKey: 'test-key',
          authToken: 'secret',
        ),
        client: chat,
      );
    });

    test('returns complete first-person narrative script', () async {
      chat.content = jsonEncode({
        'content':
            'When I first joined the military, everything changed.\n\n'
            'Looking back now, I learned perseverance.',
        'language': 'en',
      });

      final body = jsonEncode({
        'purpose': 'inspireSomeone',
        'themes': ['perseverance'],
        'themesUnsure': false,
        'answers': [
          {
            'question': 'What was happening?',
            'answer': 'I joined the military.',
          },
          {
            'question': 'What did you learn?',
            'answer': 'Perseverance.',
          },
        ],
      });

      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-builder-scripts'),
          body: body,
        ),
      );
      expect(response.statusCode, 200);
      final json = jsonDecode(await response.readAsString()) as Map;
      expect(json['content'], contains('When I first joined'));
      expect(json['providerLabel'], 'openai_via_eh_proxy');
      expect(json['promptOrTemplateVersion'], 'sb8.script.ai.v1');
      expect(
        json['content'].toString().toLowerCase(),
        isNot(contains('summary:')),
      );
    });

    test('rejects empty answers', () async {
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-builder-scripts'),
          body: jsonEncode({'answers': []}),
        ),
      );
      expect(response.statusCode, 400);
    });

    test('rejects malformed JSON', () async {
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-builder-scripts'),
          body: 'not-json',
        ),
      );
      expect(response.statusCode, 400);
    });

    test('maps empty model content to 502', () async {
      chat.content = jsonEncode({'content': '   ', 'language': 'en'});
      final response = await handler.handleGenerate(
        Request(
          'POST',
          Uri.parse('http://localhost/story-builder-scripts'),
          body: jsonEncode({
            'answers': [
              {'question': 'Q', 'answer': 'A'},
            ],
          }),
        ),
      );
      expect(response.statusCode, 502);
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

  @override
  Future<OpenAiChatResult> completeJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    return OpenAiChatResult(content: content);
  }
}
