import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';

final class EditStoryBuilderScriptRequest {
  const EditStoryBuilderScriptRequest({
    required this.scriptId,
    required this.content,
    this.editedAt,
  });

  final StoryBuilderScriptId scriptId;
  final String content;
  final DateTime? editedAt;
}
