import 'package:everyonesheroes/features/hero_story/application/dto/responses/complete_story_capture_response.dart';

/// Application-level idempotency store for capture completion (not a domain repo).
abstract interface class CaptureCompletionStore {
  CompleteStoryCaptureResponse? find(String sessionId);

  void save(String sessionId, CompleteStoryCaptureResponse response);

  void remove(String sessionId);
}

final class InMemoryCaptureCompletionStore implements CaptureCompletionStore {
  final Map<String, CompleteStoryCaptureResponse> _bySession = {};

  @override
  CompleteStoryCaptureResponse? find(String sessionId) => _bySession[sessionId];

  @override
  void save(String sessionId, CompleteStoryCaptureResponse response) {
    _bySession[sessionId] = response;
  }

  @override
  void remove(String sessionId) {
    _bySession.remove(sessionId);
  }
}
