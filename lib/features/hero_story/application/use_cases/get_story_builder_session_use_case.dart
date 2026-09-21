import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_builder_session_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';

final class GetStoryBuilderSessionUseCase
    implements UseCase<StoryBuilderSessionIdRequest, StoryBuilderSession> {
  const GetStoryBuilderSessionUseCase({
    required this._sessionRepository,
  });

  final StoryBuilderSessionRepository _sessionRepository;

  @override
  Future<Result<StoryBuilderSession>> execute(
    StoryBuilderSessionIdRequest request,
  ) async {
    try {
      final session = await _sessionRepository.findById(request.sessionId);
      if (session == null) {
        return Failure(
          'Story Builder session ${request.sessionId} not found.',
        );
      }
      return Success(session);
    } catch (e) {
      return Failure('Failed to load Story Builder session: $e');
    }
  }
}
