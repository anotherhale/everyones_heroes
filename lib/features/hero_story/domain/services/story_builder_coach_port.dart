import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';

/// Provider-independent AI Story Coach boundary (SB.7).
///
/// Returns the next interview question only — never a polished story.
/// Domain/application must not import HTTP clients or LLM SDKs.
abstract interface class StoryBuilderCoachPort {
  Future<StoryBuilderCoachSuggestion> suggestNextQuestion(
    StoryBuilderCoachRequest request,
  );
}

/// Minimized coach context derived from [StoryBuilderSession].
///
/// Does not include filesystem paths, auth tokens, or unrelated Hero profile.
final class StoryBuilderCoachRequest {
  const StoryBuilderCoachRequest({
    this.purpose,
    this.themes = const [],
    this.themesUnsure = false,
    this.turns = const [],
    this.presentedNarrativeRoles = const [],
  });

  final StoryBuilderPurpose? purpose;
  final List<StoryBuilderTheme> themes;
  final bool themesUnsure;

  /// Prior prompts and Hero-authored responses in presentation order.
  final List<StoryBuilderCoachTurn> turns;

  /// Narrative roles already associated with presented prompts.
  final List<StoryBuilderNarrativeRole> presentedNarrativeRoles;
}

/// One prior Q&A turn for the coach (Hero text is untrusted user content).
final class StoryBuilderCoachTurn {
  const StoryBuilderCoachTurn({
    required this.promptText,
    required this.ordinal,
    this.narrativeRole,
    this.responseText,
    this.skipped = false,
  });

  final String promptText;
  final int ordinal;
  final StoryBuilderNarrativeRole? narrativeRole;
  final String? responseText;
  final bool skipped;
}

/// Structured coach output. Application assigns prompt identity.
final class StoryBuilderCoachSuggestion {
  const StoryBuilderCoachSuggestion({
    this.question,
    this.narrativeRole,
    this.reason,
    this.readyToComplete = false,
  });

  /// Next single question. Null/empty only when [readyToComplete] is true.
  final String? question;

  /// Optional SB.3 narrative role for the next question.
  final StoryBuilderNarrativeRole? narrativeRole;

  /// Internal coach rationale — not shown to the Hero by default.
  final String? reason;

  /// Coach believes enough material exists. Does not mutate session status.
  final bool readyToComplete;
}

final class StoryBuilderCoachException implements Exception {
  const StoryBuilderCoachException(this.message);

  final String message;

  @override
  String toString() => 'StoryBuilderCoachException: $message';
}
