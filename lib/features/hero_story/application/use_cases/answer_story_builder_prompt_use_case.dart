import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';

final class AnswerStoryBuilderPromptUseCase
    implements UseCase<AnswerStoryBuilderPromptRequest, StoryBuilderSession> {
  const AnswerStoryBuilderPromptUseCase({
    required this._sessionRepository,
    required this._eventBus,
  });

  final StoryBuilderSessionRepository _sessionRepository;
  final EventBus _eventBus;

  @override
  Future<Result<StoryBuilderSession>> execute(
    AnswerStoryBuilderPromptRequest request,
  ) async {
    try {
      final session = await _sessionRepository.findById(request.sessionId);
      if (session == null) {
        return Failure(
          'Story Builder session ${request.sessionId} not found.',
        );
      }

      session.answerPrompt(
        responseId: request.responseId,
        promptId: request.promptId,
        text: request.text,
      );
      await _sessionRepository.save(session);

      for (final event in session.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(session);
    } catch (e) {
      return Failure('Failed to answer Story Builder prompt: $e');
    }
  }
}
