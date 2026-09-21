import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/advance_story_builder_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy_resolver.dart';

/// Presents the next strategy prompt, or completes the session when done.
///
/// Resolves [StoryBuilderQuestionStrategy] from [session.mode] so Guided and
/// AI modes never silently share the wrong strategy.
///
/// Does not create a [Story]. Does not rewrite Hero responses.
final class AdvanceStoryBuilderUseCase
    implements UseCase<AdvanceStoryBuilderRequest, AdvanceStoryBuilderResult> {
  const AdvanceStoryBuilderUseCase({
    required this._sessionRepository,
    required this._strategyResolver,
    required this._eventBus,
  });

  final StoryBuilderSessionRepository _sessionRepository;
  final StoryBuilderQuestionStrategyResolver _strategyResolver;
  final EventBus _eventBus;

  @override
  Future<Result<AdvanceStoryBuilderResult>> execute(
    AdvanceStoryBuilderRequest request,
  ) async {
    try {
      final session = await _sessionRepository.findById(request.sessionId);
      if (session == null) {
        return Failure(
          'Story Builder session ${request.sessionId} not found.',
        );
      }

      if (session.status == StoryBuilderSessionStatus.completed) {
        return Success(
          AdvanceStoryBuilderResult(
            session: session,
            currentPrompt: null,
            questioningComplete: true,
          ),
        );
      }

      if (session.status == StoryBuilderSessionStatus.abandoned) {
        return Failure(
          'Cannot advance an abandoned Story Builder session.',
        );
      }

      if (session.status == StoryBuilderSessionStatus.paused) {
        session.resume();
      }

      final questionStrategy = _strategyResolver.resolve(session.mode);
      final next = await questionStrategy.nextPrompt(session);
      if (next == null || questionStrategy.isQuestioningComplete(session)) {
        if (!session.isComplete) {
          session.complete();
        }
        await _sessionRepository.save(session);
        for (final event in session.pullDomainEvents()) {
          await _eventBus.publish(event);
        }
        return Success(
          AdvanceStoryBuilderResult(
            session: session,
            currentPrompt: null,
            questioningComplete: true,
          ),
        );
      }

      final alreadyPresented = session.prompts.any((p) => p.id == next.id);
      if (!alreadyPresented) {
        session.presentPrompt(next);
      }

      await _sessionRepository.save(session);
      for (final event in session.pullDomainEvents()) {
        await _eventBus.publish(event);
      }

      return Success(
        AdvanceStoryBuilderResult(
          session: session,
          currentPrompt: next,
          questioningComplete: false,
        ),
      );
    } on UnsupportedError catch (e) {
      return Failure(e.message ?? '$e');
    } catch (e) {
      return Failure('Failed to advance Story Builder: $e');
    }
  }
}
