import 'package:everyonesheroes/features/hero_story/application/dto/responses/approve_story_representation_response.dart';

abstract interface class ApprovalCompletionStore {
  ApproveStoryRepresentationResponse? find(String requestId);

  void save(String requestId, ApproveStoryRepresentationResponse response);

  void remove(String requestId);
}

final class InMemoryApprovalCompletionStore implements ApprovalCompletionStore {
  final Map<String, ApproveStoryRepresentationResponse> _byRequest = {};

  @override
  ApproveStoryRepresentationResponse? find(String requestId) =>
      _byRequest[requestId];

  @override
  void save(String requestId, ApproveStoryRepresentationResponse response) {
    _byRequest[requestId] = response;
  }

  @override
  void remove(String requestId) {
    _byRequest.remove(requestId);
  }
}
