import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';

final class ApproveStoryBuilderScriptRequest {
  const ApproveStoryBuilderScriptRequest({
    required this.scriptId,
    this.approvedAt,
  });

  final StoryBuilderScriptId scriptId;
  final DateTime? approvedAt;
}
