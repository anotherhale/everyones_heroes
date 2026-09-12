import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_story_script_response.dart';

/// Application-level idempotency store for authoring (not a domain repo).
abstract interface class AuthoringCompletionStore {
  GenerateStoryScriptResponse? find(String requestId);

  void save(String requestId, GenerateStoryScriptResponse response);

  void remove(String requestId);
}

final class InMemoryAuthoringCompletionStore
    implements AuthoringCompletionStore {
  final Map<String, GenerateStoryScriptResponse> _byRequest = {};

  @override
  GenerateStoryScriptResponse? find(String requestId) => _byRequest[requestId];

  @override
  void save(String requestId, GenerateStoryScriptResponse response) {
    _byRequest[requestId] = response;
  }

  @override
  void remove(String requestId) {
    _byRequest.remove(requestId);
  }
}
