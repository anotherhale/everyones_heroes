import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// A prompt presented to the Hero during Story Builder.
///
/// Text is stored exactly as presented. Domain does not rewrite prompts.
final class StoryBuilderPrompt extends ValueObject {
  StoryBuilderPrompt({
    required this.id,
    required this.text,
    required this.ordinal,
  }) {
    if (text.trim().isEmpty) {
      throw ArgumentError('Prompt text cannot be empty.');
    }
    if (ordinal < 0) {
      throw ArgumentError('Prompt ordinal cannot be negative.');
    }
  }

  final StoryBuilderPromptId id;
  final String text;
  final int ordinal;

  @override
  List<Object?> get equalityProps => [id, text, ordinal];
}
