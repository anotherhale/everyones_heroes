import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_understanding_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/deterministic_story_structure.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_key_story_elements.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_narrative_element.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_significant_event.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_theme.dart';

/// Derived Story Understanding for a [StoryBuilderSession] (SB.8).
///
/// Answers: "What story material has the Hero actually given us?"
/// Does **not** author a polished story, create a [Story], or replace
/// Hero-authored responses. Prefer recomputation over persistence.
///
/// Distinct from HS.4 [StoryUnderstanding], which analyzes Story
/// representation catalog candidates after a Story exists.
final class StoryBuilderUnderstanding extends ValueObject {
  StoryBuilderUnderstanding({
    required this.sessionId,
    required this.kind,
    required this.structure,
    required this.intentSnapshot,
    required this.processingVersion,
    required this.analyzedAt,
    Iterable<UnderstoodTheme>? themes,
    Iterable<UnderstoodNarrativeElement>? narrativeElements,
    this.keyElements = const UnderstoodKeyStoryElements(),
    Iterable<UnderstoodSignificantEvent>? significantEvents,
    this.derivedSummary,
    this.providerLabel,
    this.modelLabel,
  }) : themes = List.unmodifiable(themes ?? const <UnderstoodTheme>[]),
       narrativeElements = List.unmodifiable(
         narrativeElements ?? const <UnderstoodNarrativeElement>[],
       ),
       significantEvents = List.unmodifiable(
         significantEvents ?? const <UnderstoodSignificantEvent>[],
       ) {
    if (processingVersion.trim().isEmpty) {
      throw ArgumentError('processingVersion cannot be empty.');
    }
    if (sessionId != structure.sessionId) {
      throw ArgumentError(
        'Understanding sessionId must match embedded structure.sessionId.',
      );
    }
    final summary = derivedSummary?.trim();
    if (summary != null && summary.isEmpty) {
      throw ArgumentError('derivedSummary cannot be blank when provided.');
    }
    if (summary != null && summary.length > maxDerivedSummaryLength) {
      throw ArgumentError(
        'derivedSummary exceeds $maxDerivedSummaryLength chars.',
      );
    }
    if (this.significantEvents.length > maxSignificantEvents) {
      throw ArgumentError(
        'significantEvents exceeds $maxSignificantEvents entries.',
      );
    }
    if (this.themes.length > maxThemes) {
      throw ArgumentError('themes exceeds $maxThemes entries.');
    }
  }

  static const int maxDerivedSummaryLength = 1000;
  static const int maxSignificantEvents = 20;
  static const int maxThemes = 20;

  static const String deterministicProcessingVersion = 'sb8.deterministic.v1';
  static const String aiProcessingVersion = 'sb8.ai.v1';

  final StoryBuilderSessionId sessionId;
  final StoryBuilderUnderstandingKind kind;

  /// SB.4 structural map reused — not duplicated independently.
  final DeterministicStoryStructure structure;

  /// Intent snapshot at analysis time (purpose/themes preserved, not mutated).
  final StoryBuilderIntent intentSnapshot;

  final String processingVersion;
  final DateTime analyzedAt;
  final List<UnderstoodTheme> themes;
  final List<UnderstoodNarrativeElement> narrativeElements;
  final UnderstoodKeyStoryElements keyElements;
  final List<UnderstoodSignificantEvent> significantEvents;

  /// Optional derived analysis summary — never Hero-authored source material.
  final String? derivedSummary;

  final String? providerLabel;
  final String? modelLabel;

  bool get isDeterministic =>
      kind == StoryBuilderUnderstandingKind.deterministic;

  bool get isAiEnhanced => kind == StoryBuilderUnderstandingKind.aiEnhanced;

  int get populatedNarrativeElementCount => narrativeElements.length;

  @override
  List<Object?> get equalityProps => [
    sessionId,
    kind,
    structure,
    intentSnapshot,
    processingVersion,
    analyzedAt,
    keyElements,
    derivedSummary,
    providerLabel,
    modelLabel,
    ...themes,
    ...narrativeElements,
    ...significantEvents,
  ];
}
