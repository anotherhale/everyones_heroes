import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/build_deterministic_story_structure_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_structure_builder.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/deterministic_story_structure.dart';

/// Derives a deterministic narrative structure from a Story Builder session.
///
/// Does not persist the structure, create a Story, or invoke AI.
final class BuildDeterministicStoryStructureUseCase
    implements
        UseCase<
          BuildDeterministicStoryStructureRequest,
          DeterministicStoryStructure
        > {
  const BuildDeterministicStoryStructureUseCase({
    required this._sessionRepository,
    this._builder = const DeterministicStoryStructureBuilder(),
  });

  final StoryBuilderSessionRepository _sessionRepository;
  final DeterministicStoryStructureBuilder _builder;

  @override
  Future<Result<DeterministicStoryStructure>> execute(
    BuildDeterministicStoryStructureRequest request,
  ) async {
    try {
      final session = await _sessionRepository.findById(request.sessionId);
      if (session == null) {
        return Failure(
          'Story Builder session ${request.sessionId} not found.',
        );
      }

      if (session.status == StoryBuilderSessionStatus.abandoned) {
        return Failure(
          'Cannot build structure for an abandoned Story Builder session.',
        );
      }

      final structure = _builder.build(session);
      return Success(structure);
    } catch (e) {
      return Failure('Failed to build deterministic story structure: $e');
    }
  }
}
