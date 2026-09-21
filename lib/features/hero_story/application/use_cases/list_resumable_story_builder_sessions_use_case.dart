import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/list_resumable_story_builder_sessions_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';

/// Lists in-progress and paused Story Builder sessions for a Hero (newest first).
///
/// Completed and abandoned sessions are excluded — SB.6 does not reopen them.
final class ListResumableStoryBuilderSessionsUseCase
    implements
        UseCase<
          ListResumableStoryBuilderSessionsRequest,
          List<StoryBuilderSession>
        > {
  const ListResumableStoryBuilderSessionsUseCase({
    required this._sessionRepository,
  });

  final StoryBuilderSessionRepository _sessionRepository;

  @override
  Future<Result<List<StoryBuilderSession>>> execute(
    ListResumableStoryBuilderSessionsRequest request,
  ) async {
    try {
      final sessions = await _sessionRepository.findResumableByHeroId(
        request.heroId,
      );
      return Success(sessions);
    } catch (e) {
      return Failure('Failed to list resumable Story Builder sessions: $e');
    }
  }
}
