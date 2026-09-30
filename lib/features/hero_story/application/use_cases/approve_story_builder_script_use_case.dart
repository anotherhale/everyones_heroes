import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_builder_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script.dart';

/// Explicit Hero approval of a Story Builder script (SB.8).
///
/// Approves the **script representation**, not the final Story lifecycle.
/// Does not create a Story — use [MaterializeStoryBuilderScriptUseCase].
final class ApproveStoryBuilderScriptUseCase
    implements UseCase<ApproveStoryBuilderScriptRequest, StoryBuilderScript> {
  const ApproveStoryBuilderScriptUseCase({
    required StoryBuilderScriptRepository scriptRepository,
  }) : _scriptRepository = scriptRepository;

  final StoryBuilderScriptRepository _scriptRepository;

  @override
  Future<Result<StoryBuilderScript>> execute(
    ApproveStoryBuilderScriptRequest request,
  ) async {
    try {
      final existing = await _scriptRepository.findById(request.scriptId);
      if (existing == null) {
        return Failure(
          'Story Builder script ${request.scriptId} not found.',
        );
      }

      final approved = existing.approve(at: request.approvedAt);
      await _scriptRepository.save(approved);
      return Success(approved);
    } catch (e) {
      return Failure('Failed to approve Story Builder script: $e');
    }
  }
}
