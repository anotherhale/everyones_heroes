import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';

/// Creates a durable Story Builder session. Does not create a [Story].
final class StartStoryBuilderSessionUseCase
    implements UseCase<StartStoryBuilderSessionRequest, StoryBuilderSession> {
  const StartStoryBuilderSessionUseCase({
    required this._sessionRepository,
    required this._eventBus,
  });

  final StoryBuilderSessionRepository _sessionRepository;
  final EventBus _eventBus;

  @override
  Future<Result<StoryBuilderSession>> execute(
    StartStoryBuilderSessionRequest request,
  ) async {
    try {
      if (await _sessionRepository.exists(request.sessionId)) {
        return Failure(
          'Story Builder session ${request.sessionId} already exists.',
        );
      }

      final session = StoryBuilderSession.create(
        id: request.sessionId,
        heroId: request.heroId,
        mode: request.mode,
        intent: request.intent,
        storyId: request.storyId,
      );

      await _sessionRepository.save(session);

      for (final event in session.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(session);
    } catch (e) {
      return Failure('Failed to start Story Builder session: $e');
    }
  }
}
