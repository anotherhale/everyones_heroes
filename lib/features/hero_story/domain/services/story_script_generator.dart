import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';

/// Provider-independent port that transforms Hero Story Builder material into
/// a complete first-person narrative script draft (SB.8).
///
/// AI may reshape supplied answers into coherent prose. It must not invent
/// experiences, facts, achievements, motivations, or quotations.
///
/// Vendor adapters (OpenAI via EH proxy, etc.) live in infrastructure.
abstract interface class StoryScriptGenerator {
  Future<StoryScriptGenerationDraft> generate(
    StoryScriptGenerationMaterial material,
  );
}

/// Canonical Hero material collected from a durable StoryBuilderSession.
final class StoryScriptGenerationMaterial {
  const StoryScriptGenerationMaterial({
    required this.sessionId,
    required this.answers,
    this.purpose,
    this.themes = const [],
    this.themesUnsure = false,
    this.language,
  });

  final StoryBuilderSessionId sessionId;
  final StoryBuilderPurpose? purpose;
  final List<StoryBuilderTheme> themes;
  final bool themesUnsure;
  final LanguageCode? language;

  /// Ordered question/answer pairs in narrative interview order.
  final List<StoryScriptSourceAnswer> answers;
}

final class StoryScriptSourceAnswer {
  const StoryScriptSourceAnswer({
    required this.question,
    required this.answer,
    this.responseId,
  });

  final String question;
  final String answer;
  final String? responseId;
}

/// Non-authoritative AI (or deterministic) draft — never auto-approved.
final class StoryScriptGenerationDraft {
  const StoryScriptGenerationDraft({
    required this.content,
    required this.language,
    this.providerLabel,
    this.processingVersion = defaultProcessingVersion,
  });

  static const String defaultProcessingVersion = 'sb8.script.ai.v1';

  final String content;
  final LanguageCode language;
  final String? providerLabel;
  final String processingVersion;
}

final class StoryScriptGeneratorException implements Exception {
  const StoryScriptGeneratorException(this.message);

  final String message;

  @override
  String toString() => 'StoryScriptGeneratorException: $message';
}
