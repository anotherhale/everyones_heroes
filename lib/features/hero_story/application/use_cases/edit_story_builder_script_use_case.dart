import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_builder_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script.dart';

/// Persists Hero edits to a Story Builder script (SB.8).
///
/// Edits clear approval — the Hero must re-approve before materialization.
final class EditStoryBuilderScriptUseCase
    implements UseCase<EditStoryBuilderScriptRequest, StoryBuilderScript> {
  const EditStoryBuilderScriptUseCase({
    required StoryBuilderScriptRepository scriptRepository,
  }) : _scriptRepository = scriptRepository;

  final StoryBuilderScriptRepository _scriptRepository;

  @override
  Future<Result<StoryBuilderScript>> execute(
    EditStoryBuilderScriptRequest request,
  ) async {
    try {
      final existing = await _scriptRepository.findById(request.scriptId);
      if (existing == null) {
        return Failure(
          'Story Builder script ${request.scriptId} not found.',
        );
      }

      final edited = existing.withEditedContent(
        request.content,
        at: request.editedAt,
      );
      await _scriptRepository.save(edited);
      return Success(edited);
    } catch (e) {
      return Failure('Failed to edit Story Builder script: $e');
    }
  }
}
