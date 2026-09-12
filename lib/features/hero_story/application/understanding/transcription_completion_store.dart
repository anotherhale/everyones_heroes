import 'package:everyonesheroes/features/hero_story/application/dto/responses/transcribe_story_response.dart';

/// Application-level idempotency store for transcription (not a domain repo).
abstract interface class TranscriptionCompletionStore {
  TranscribeStoryResponse? find(String requestId);

  void save(String requestId, TranscribeStoryResponse response);

  void remove(String requestId);
}

final class InMemoryTranscriptionCompletionStore
    implements TranscriptionCompletionStore {
  final Map<String, TranscribeStoryResponse> _byRequest = {};

  @override
  TranscribeStoryResponse? find(String requestId) => _byRequest[requestId];

  @override
  void save(String requestId, TranscribeStoryResponse response) {
    _byRequest[requestId] = response;
  }

  @override
  void remove(String requestId) {
    _byRequest.remove(requestId);
  }
}
