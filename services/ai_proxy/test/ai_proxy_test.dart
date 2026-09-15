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

  test('ProxyConfig requires OPENAI_API_KEY', () {
    expect(
      () => ProxyConfig.fromEnvironment(environment: {}),
      throwsStateError,
    );
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
