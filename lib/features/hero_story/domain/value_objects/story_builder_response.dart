import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Derived progress view over a Story Builder session.
final class StoryBuilderProgress extends ValueObject {
  const StoryBuilderProgress({
    required this.presentedPromptCount,
    required this.responseCount,
    required this.answeredCount,
    required this.skippedCount,
    this.currentPromptOrdinal,
  });

  final int presentedPromptCount;
  final int responseCount;
  final int answeredCount;
  final int skippedCount;

  /// Ordinal of the most recently presented prompt, if any.
  final int? currentPromptOrdinal;

  bool get hasStarted => presentedPromptCount > 0;

  @override
  List<Object?> get equalityProps => [
    presentedPromptCount,
    responseCount,
    answeredCount,
    skippedCount,
    currentPromptOrdinal,
  ];
}

/// Hero-authored source material for one prompt (immutable snapshot).
///
/// Owned by [StoryBuilderSession]. Identity is stable across edits so later
/// section maps (SB.4) can reference response IDs without copying text.
final class StoryBuilderResponse extends ValueObject {
  StoryBuilderResponse({
    required this.id,
    required this.promptId,
    required this.ordinal,
    required this.createdAt,
    this.text,
    this.skipped = false,
    this.updatedAt,
  }) {
    if (ordinal < 0) {
      throw ArgumentError('Response ordinal cannot be negative.');
    }
    if (skipped) {
      if (text != null && text!.trim().isNotEmpty) {
        throw ArgumentError('Skipped responses cannot carry answer text.');
      }
    } else {
      if (text == null) {
        throw ArgumentError('Answered responses require text.');
      }
      // Preserve exact user text including whitespace; only reject null.
    }
  }

  final StoryBuilderResponseId id;
  final StoryBuilderPromptId promptId;
  final int ordinal;

  /// Exact Hero-authored text. Null only when [skipped] is true.
  final String? text;

  final bool skipped;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isEdited => updatedAt != null;

  bool get hasText => text != null;

  StoryBuilderResponse withEditedText(String newText, {DateTime? at}) {
    if (skipped) {
      throw StateError('Cannot edit a skipped response; answer it instead.');
    }
    return StoryBuilderResponse(
      id: id,
      promptId: promptId,
      ordinal: ordinal,
      text: newText,
      skipped: false,
      createdAt: createdAt,
      updatedAt: at ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get equalityProps => [
    id,
    promptId,
    ordinal,
    text,
    skipped,
    createdAt,
    updatedAt,
  ];
}
