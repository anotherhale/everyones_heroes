import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_builder_session_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';

final class ResumeStoryBuilderSessionUseCase
    implements UseCase<StoryBuilderSessionIdRequest, StoryBuilderSession> {
  const ResumeStoryBuilderSessionUseCase({
    required this._sessionRepository,
    required this._eventBus,
  });

  final StoryBuilderSessionRepository _sessionRepository;
  final EventBus _eventBus;

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

      session.resume();
      await _sessionRepository.save(session);

      for (final event in session.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(session);
    } catch (e) {
      return Failure('Failed to resume Story Builder session: $e');
    }
  }
}
