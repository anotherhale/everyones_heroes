import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';

/// Request to generate a durable Story Builder script from a session (SB.8).
final class GenerateStoryBuilderScriptRequest {
  const GenerateStoryBuilderScriptRequest({
    required this.sessionId,
    this.scriptId,
    this.language,
    this.createdAt,
    this.replaceExistingDraft = false,
    this.confirmDiscardHeroEdits = false,
  });

  final StoryBuilderSessionId sessionId;

  /// Optional pre-allocated identity (tests / idempotent clients).
  final StoryBuilderScriptId? scriptId;

  final LanguageCode? language;
  final DateTime? createdAt;

  /// When true, creates a new draft even if a draft already exists.
  final bool replaceExistingDraft;

  /// Required when regenerating would discard Hero edits on the latest draft.
  final bool confirmDiscardHeroEdits;
}
