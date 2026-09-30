import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';

final class MaterializeStoryBuilderScriptRequest {
  const MaterializeStoryBuilderScriptRequest({
    required this.scriptId,
    this.materializedAt,
  });

  final StoryBuilderScriptId scriptId;
  final DateTime? materializedAt;
}
