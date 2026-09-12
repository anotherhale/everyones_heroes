import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/observation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';

/// Observational note derived from story source material.
///
/// Prefer observations over conclusions. Must not assert sensitive Hero identity.
final class StoryObservation extends ValueObject {
  StoryObservation({
    required this.kind,
    required this.content,
    this.supportLevel,
    this.sourceSpan,
  }) {
    if (content.trim().isEmpty) {
      throw ArgumentError('Observation content cannot be empty.');
    }
    _rejectForbiddenIdentityClaims(content);
  }

  final ObservationKind kind;
  final String content;
  final AnalysisSupportLevel? supportLevel;
  final SourceSpanReference? sourceSpan;

  static final List<RegExp> _forbiddenIdentityPatterns = [
    RegExp(r'\bhero\s+is\s+(a\s+)?christian\b', caseSensitive: false),
    RegExp(r'\bhero\s+is\s+(a\s+)?muslim\b', caseSensitive: false),
    RegExp(r'\bhero\s+is\s+(a\s+)?jewish\b', caseSensitive: false),
    RegExp(r'\bhero\s+is\s+(a\s+)?buddhist\b', caseSensitive: false),
    RegExp(r'\bhero\s+(has|suffers from)\s+(ptsd|depression|bipolar)\b',
        caseSensitive: false),
    RegExp(r'\bhero.?s\s+(sexual orientation|political belief)\b',
        caseSensitive: false),
    RegExp(r'\bdiagnos(e|is|ed)\b', caseSensitive: false),
  ];

  static void _rejectForbiddenIdentityClaims(String content) {
    for (final pattern in _forbiddenIdentityPatterns) {
      if (pattern.hasMatch(content)) {
        throw ArgumentError(
          'Story observation must not assert sensitive Hero identity claims.',
        );
      }
    }
  }

  @override
  List<Object?> get equalityProps => [
    kind,
    content,
    supportLevel,
    sourceSpan,
  ];
}
