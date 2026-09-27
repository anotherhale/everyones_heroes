import 'dart:convert';

import 'package:ai_proxy/src/openai_chat_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAiChatClient.buildChatRequest', () {
    test('GPT-5.6 omits temperature and preserves contract fields', () {
      final body = OpenAiChatClient.buildChatRequest(
        model: 'gpt-5.6',
        systemPrompt: 'system',
        userPrompt: 'user',
      );

      expect(body['model'], 'gpt-5.6');
      expect(body.containsKey('temperature'), isFalse);
      expect(body['response_format'], {'type': 'json_object'});
      expect(body['messages'], [
        {'role': 'system', 'content': 'system'},
        {'role': 'user', 'content': 'user'},
      ]);
    });

    test('gpt-5.6-luna likewise omits temperature', () {
      final body = OpenAiChatClient.buildChatRequest(
        model: 'gpt-5.6-luna',
        systemPrompt: 's',
        userPrompt: 'u',
      );

      expect(body['model'], 'gpt-5.6-luna');
      expect(body.containsKey('temperature'), isFalse);
      expect(body['response_format'], {'type': 'json_object'});
      expect(body['messages'], [
        {'role': 'system', 'content': 's'},
        {'role': 'user', 'content': 'u'},
      ]);
    });

    test('legacy gpt-4o-mini still sends temperature 0.4', () {
      final body = OpenAiChatClient.buildChatRequest(
        model: 'gpt-4o-mini',
        systemPrompt: 'system',
        userPrompt: 'user',
      );

      expect(body['model'], 'gpt-4o-mini');
      expect(body['temperature'], 0.4);
      expect(body['response_format'], {'type': 'json_object'});
      expect(body['messages'], [
        {'role': 'system', 'content': 'system'},
        {'role': 'user', 'content': 'user'},
      ]);
    });
  });

  group('OpenAiChatClient.completeJson request body', () {
    test(
      'GPT-5.6 omits temperature while keeping model and json_object format',
      () async {
        late http.Request captured;
        final client = OpenAiChatClient(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-5.6',
          client: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': '{"ok":true}'},
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.close);

        final result = await client.completeJson(
          systemPrompt: 'system',
          userPrompt: 'user',
        );

        expect(captured.url.path, '/v1/chat/completions');
        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(body['model'], 'gpt-5.6');
        expect(body.containsKey('temperature'), isFalse);
        expect(body['response_format'], {'type': 'json_object'});
        expect(body['messages'], [
          {'role': 'system', 'content': 'system'},
          {'role': 'user', 'content': 'user'},
        ]);
        expect(result.content, '{"ok":true}');
      },
    );

    test(
      'gpt-5.6-luna serialized HTTP body omits temperature',
      () async {
        late Map<String, dynamic> body;
        final client = OpenAiChatClient(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-5.6-luna',
          client: MockClient((request) async {
            body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': '{}'},
                  },
                ],
              }),
              200,
            );
          }),
        );
        addTearDown(client.close);

        await client.completeJson(systemPrompt: 's', userPrompt: 'u');

        expect(body['model'], 'gpt-5.6-luna');
        expect(body.containsKey('temperature'), isFalse);
        expect(body['response_format'], {'type': 'json_object'});
        expect(body['messages'], [
          {'role': 'system', 'content': 's'},
          {'role': 'user', 'content': 'u'},
        ]);
      },
    );

    test(
      'gpt-5-mini likewise omits temperature (GPT-5 family)',
      () async {
        late Map<String, dynamic> body;
        final client = OpenAiChatClient(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-5-mini',
          client: MockClient((request) async {
            body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': '{}'},
                  },
                ],
              }),
              200,
            );
          }),
        );
        addTearDown(client.close);

        await client.completeJson(systemPrompt: 's', userPrompt: 'u');

        expect(body['model'], 'gpt-5-mini');
        expect(body.containsKey('temperature'), isFalse);
        expect(body['response_format'], {'type': 'json_object'});
      },
    );

    test(
      'legacy gpt-4o-mini still sends temperature 0.4 with json_object',
      () async {
        late Map<String, dynamic> body;
        final client = OpenAiChatClient(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
          client: MockClient((request) async {
            body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': '{"q":1}'},
                  },
                ],
              }),
              200,
            );
          }),
        );
        addTearDown(client.close);

        final result = await client.completeJson(
          systemPrompt: 'system',
          userPrompt: 'user',
        );

        expect(body['model'], 'gpt-4o-mini');
        expect(body['temperature'], 0.4);
        expect(body['response_format'], {'type': 'json_object'});
        expect(body['messages'], [
          {'role': 'system', 'content': 'system'},
          {'role': 'user', 'content': 'user'},
        ]);
        expect(result.content, '{"q":1}');
      },
    );
  });
}
