import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/cancel_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';

final class CancelStoryCaptureResponse {
  const CancelStoryCaptureResponse({required this.cancelled});

  final bool cancelled;
}

final class CancelStoryCaptureUseCase
    implements UseCase<CancelStoryCaptureRequest, CancelStoryCaptureResponse> {
  CancelStoryCaptureUseCase({
    required StoryMediaStoragePort mediaStorage,
    CaptureCompletionStore? completionStore,
  }) : _mediaStorage = mediaStorage,
       _completionStore = completionStore ?? InMemoryCaptureCompletionStore();

  final StoryMediaStoragePort _mediaStorage;
  final CaptureCompletionStore _completionStore;

  @override
  Future<Result<CancelStoryCaptureResponse>> execute(
    CancelStoryCaptureRequest request,
  ) async {
    try {
      final sessionId = request.sessionId.trim();
      if (sessionId.isEmpty) {
        return const Failure('Capture sessionId is required.');
      }

      _completionStore.remove(sessionId);

      if (request.mediaReference != null) {
        await _mediaStorage.delete(request.mediaReference!);
      }

      return const Success(CancelStoryCaptureResponse(cancelled: true));
    } catch (e) {
      return Failure('Failed to cancel story capture: $e');
    }
  }
}
