import 'package:everyonesheroes/features/hero_story/application/dto/responses/generate_story_understanding_response.dart';

/// Application-level idempotency store for understanding generation.
abstract interface class UnderstandingCompletionStore {
  GenerateStoryUnderstandingResponse? find(String requestId);

  void save(String requestId, GenerateStoryUnderstandingResponse response);

  void remove(String requestId);
}

final class InMemoryUnderstandingCompletionStore
    implements UnderstandingCompletionStore {
  final Map<String, GenerateStoryUnderstandingResponse> _byRequest = {};

  @override
  GenerateStoryUnderstandingResponse? find(String requestId) =>
      _byRequest[requestId];

  @override
  void save(String requestId, GenerateStoryUnderstandingResponse response) {
    _byRequest[requestId] = response;
  }

  @override
  void remove(String requestId) {
    _byRequest.remove(requestId);
  }
}
