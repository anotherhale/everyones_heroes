import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';

/// A prompt presented to the Hero during Story Builder.
///
/// Text is stored exactly as presented. Domain does not rewrite prompts.
final class StoryBuilderPrompt extends ValueObject {
  StoryBuilderPrompt({
    required this.id,
    required this.text,
    required this.ordinal,
    this.narrativeRole,
    this.isOptional = true,
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

  /// Structural role for deterministic mapping (SB.3/SB.4). Optional for ad-hoc prompts.
  final StoryBuilderNarrativeRole? narrativeRole;

  /// When true, the Hero may skip without answering.
  final bool isOptional;

  @override
  List<Object?> get equalityProps => [
    id,
    text,
    ordinal,
    narrativeRole,
    isOptional,
  ];
}
