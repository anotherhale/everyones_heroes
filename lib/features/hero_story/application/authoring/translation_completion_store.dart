import 'package:everyonesheroes/features/hero_story/application/dto/responses/translate_story_representation_response.dart';

abstract interface class TranslationCompletionStore {
  TranslateStoryRepresentationResponse? find(String requestId);

  void save(String requestId, TranslateStoryRepresentationResponse response);

  void remove(String requestId);
}

final class InMemoryTranslationCompletionStore
    implements TranslationCompletionStore {
  final Map<String, TranslateStoryRepresentationResponse> _byRequest = {};

  @override
  TranslateStoryRepresentationResponse? find(String requestId) =>
      _byRequest[requestId];

  @override
  void save(String requestId, TranslateStoryRepresentationResponse response) {
    _byRequest[requestId] = response;
  }

  @override
  void remove(String requestId) {
    _byRequest.remove(requestId);
  }
}
