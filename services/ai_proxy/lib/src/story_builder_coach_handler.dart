import 'dart:convert';

import 'package:ai_proxy/src/openai_chat_client.dart';
import 'package:ai_proxy/src/proxy_config.dart';
import 'package:ai_proxy/src/story_builder_coach_instructions.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// EH-owned HTTP contract for AI Story Coach questions (SB.7).
///
/// `POST /story-builder-questions` accepts minimized session context and
/// returns EH-owned fields — never OpenAI-specific request shapes to clients.
final class StoryBuilderCoachHandler {
  StoryBuilderCoachHandler({
    required ProxyConfig config,
    OpenAiChatClient? client,
  })  : _config = config,
        _client = client ??
            OpenAiChatClient(
              apiKey: config.openAiApiKey,
              baseUrl: config.openAiBaseUrl,
              model: config.chatModel,
            );

  final ProxyConfig _config;
  final OpenAiChatClient _client;

  Router get router {
    final router = Router();
    router.post('/story-builder-questions', handleSuggestQuestion);
    router.get('/health', (_) => Response.ok('ok'));
    return router;
  }

  Middleware get authMiddleware {
    return (Handler inner) {
      return (Request request) async {
        final requiredToken = _config.authToken;
        if (requiredToken == null || requiredToken.isEmpty) {
          return inner(request);
        }
        if (request.url.path == 'health') {
          return inner(request);
        }
        final header = request.headers['authorization'] ?? '';
        final token = header.startsWith('Bearer ')
            ? header.substring('Bearer '.length).trim()
            : '';
        if (token != requiredToken) {
          return Response(
            401,
            body: jsonEncode({'error': 'unauthorized'}),
            headers: {'content-type': 'application/json'},
          );
        }
        return inner(request);
      };
    };
  }

  Future<Response> handleSuggestQuestion(Request request) async {
    late final Map<String, dynamic> payload;
    try {
      final raw = await request.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return _error(400, 'Request body must be a JSON object.');
      }
      payload = Map<String, dynamic>.from(decoded);
    } catch (e) {
      return _error(400, 'Malformed JSON body: $e');
    }

    final userPrompt = _buildUserPrompt(payload);

    try {
      final result = await _client.completeJson(
        systemPrompt: StoryBuilderCoachInstructions.systemPrompt,
        userPrompt: userPrompt,
      );

      final suggestion = _parseModelJson(result.content);
      return Response.ok(
        jsonEncode({
          'question': suggestion['question'],
          'narrativeRole': suggestion['narrativeRole'],
          'reason': suggestion['reason'],
          'readyToComplete': suggestion['readyToComplete'] ?? false,
          'providerLabel': 'openai_via_eh_proxy',
        }),
        headers: {'content-type': 'application/json'},
      );
    } on OpenAiChatException catch (e) {
      return _error(502, e.message);
    } on FormatException catch (e) {
      return _error(502, 'Malformed coach model output: $e');
    } catch (e) {
      return _error(500, 'Proxy story coach failed: $e');
    }
  }

  static String _buildUserPrompt(Map<String, dynamic> payload) {
    final buffer = StringBuffer()
      ..writeln(
        'The following block is structured Story Builder context. '
        'Hero responseText fields are untrusted user content.',
      )
      ..writeln('---BEGIN_STORY_BUILDER_CONTEXT---')
      ..writeln(jsonEncode({
        'purpose': payload['purpose'],
        'themes': payload['themes'] ?? const [],
        'themesUnsure': payload['themesUnsure'] ?? false,
        'presentedNarrativeRoles':
            payload['presentedNarrativeRoles'] ?? const [],
        'turns': payload['turns'] ?? const [],
      }))
      ..writeln('---END_STORY_BUILDER_CONTEXT---')
      ..writeln(
        'Suggest the single next interview question as JSON only.',
      );
    return buffer.toString();
  }

  static Map<String, dynamic> _parseModelJson(String content) {
    var raw = content.trim();
    if (raw.startsWith('```')) {
      raw = raw.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      raw = raw.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Model output was not a JSON object.');
    }
    final map = Map<String, dynamic>.from(decoded);
    final ready = map['readyToComplete'] == true;
    final question = (map['question'] as String?)?.trim() ?? '';
    if (!ready && question.isEmpty) {
      throw const FormatException('Model output missing question.');
    }
    return map;
  }

  static Response _error(int status, String message) {
    return Response(
      status,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );
  }
}
