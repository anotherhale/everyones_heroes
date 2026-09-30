import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Provenance linking a [StoryBuilderScript] back to Hero material.
///
/// Answers: "Where did this Story Script come from?" → [sessionId].
final class StoryBuilderScriptProvenance extends ValueObject {
  StoryBuilderScriptProvenance({
    required this.sessionId,
    required this.processingVersion,
    this.providerLabel,
    this.replacedScriptId,
  }) {
    if (processingVersion.trim().isEmpty) {
      throw ArgumentError('processingVersion cannot be empty.');
    }
    final label = providerLabel?.trim();
    if (label != null && label.isEmpty) {
      throw ArgumentError('providerLabel cannot be blank when provided.');
    }
  }

  /// Canonical Story Builder session whose answers grounded this script.
  final StoryBuilderSessionId sessionId;

  final String processingVersion;

  /// Observability only — never an OpenAI/vendor credential or SDK type.
  final String? providerLabel;

  /// Prior script id when this draft was produced via regeneration.
  final String? replacedScriptId;

  @override
  List<Object?> get equalityProps => [
        sessionId,
        processingVersion,
        providerLabel,
        replacedScriptId,
      ];
}
