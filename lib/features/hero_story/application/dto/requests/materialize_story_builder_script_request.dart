import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';

/// Materializes an approved Story Builder script into a canonical [Story].
///
/// [title] is the Hero-provided Story title. It belongs to the Story (via
/// StoryProposal), not the StoryBuilderSession or the AI script.
final class MaterializeStoryBuilderScriptRequest {
  const MaterializeStoryBuilderScriptRequest({
    required this.scriptId,
    required this.title,
    this.materializedAt,
  });

  final StoryBuilderScriptId scriptId;

  /// Hero-chosen Story title. Trimmed and validated as [StoryTitle] by the
  /// materialization use case.
  final String title;

  final DateTime? materializedAt;
}
