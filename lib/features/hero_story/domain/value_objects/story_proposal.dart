import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// Derived, reviewable candidate Story structure/content (SB.9).
///
/// Not a [Story]. Not a [StoryBuilderSession]. Not [StoryBuilderUnderstanding].
///
/// Identity: each new generation allocates a new [StoryProposalId]. Persisted
/// proposals keep that id across reloads. Never equals session or Story ids.
final class StoryProposal extends ValueObject {
  StoryProposal({
    required this.id,
    required this.sessionId,
    required this.intent,
    required this.provenance,
    required this.lifecycle,
    required this.createdAt,
    required this.updatedAt,
    required Iterable<StoryProposalSection> sections,
    this.title,
    this.narrative,
    this.derivedSummary,
  }) : sections = List.unmodifiable(sections.toList()) {
    if (sessionId != provenance.sessionId) {
      throw ArgumentError(
        'StoryProposal.sessionId must match provenance.sessionId.',
      );
    }
    if (this.sections.isEmpty) {
      throw ArgumentError('StoryProposal requires at least one section.');
    }
    for (var i = 0; i < this.sections.length; i++) {
      if (this.sections[i].order != i) {
        throw ArgumentError(
          'Proposal sections must be contiguous from order 0.',
        );
      }
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
    final narrativeText = narrative?.trim();
    if (narrativeText != null && narrativeText.isEmpty) {
      throw ArgumentError('narrative cannot be blank when provided.');
    }
  }

  static const int maxDerivedSummaryLength = 1000;

  /// Processing version for deterministic SB.9 construction.
  static const String deterministicProcessingVersion = 'sb9.deterministic.v1';

  final StoryProposalId id;
  final StoryBuilderSessionId sessionId;

  /// Explicit absence when no defensible title exists (no Builder title field).
  final StoryTitle? title;

  /// Assembled candidate narrative from Hero-authored section content only.
  /// Null when no answered material produced content.
  final String? narrative;

  final List<StoryProposalSection> sections;

  /// Intent snapshot at proposal time (purpose/themes; not mutated).
  final StoryBuilderIntent intent;

  final StoryProposalProvenance provenance;
  final StoryProposalLifecycleStatus lifecycle;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional Understanding-derived summary — never treated as Hero text.
  final String? derivedSummary;

  int get sectionCount => sections.length;

  int get populatedSectionCount =>
      sections.where((s) => s.hasSourceMaterial).length;

  int get skippedSectionCount => sections.where((s) => s.wasSkipped).length;

  int get emptySectionCount => sections.where((s) => s.isEmpty).length;

  StoryProposalSection? sectionForRole(StoryBuilderNarrativeRole role) {
    for (final section in sections) {
      if (section.narrativeRole == role) {
        return section;
      }
    }
    return null;
  }

  /// Content equivalence excluding identity and timestamps (for determinism).
  bool isContentEquivalentTo(StoryProposal other) {
    if (sessionId != other.sessionId) return false;
    if (title != other.title) return false;
    if (narrative != other.narrative) return false;
    if (intent != other.intent) return false;
    if (lifecycle != other.lifecycle) return false;
    if (derivedSummary != other.derivedSummary) return false;
    if (provenance.derivationKind != other.provenance.derivationKind) {
      return false;
    }
    if (provenance.processingVersion != other.provenance.processingVersion) {
      return false;
    }
    if (sections.length != other.sections.length) return false;
    for (var i = 0; i < sections.length; i++) {
      final a = sections[i];
      final b = other.sections[i];
      if (a.narrativeRole != b.narrativeRole ||
          a.order != b.order ||
          a.content != b.content ||
          a.wasSkipped != b.wasSkipped ||
          a.contentOrigin != b.contentOrigin ||
          a.sourceResponseIds.length != b.sourceResponseIds.length) {
        return false;
      }
      for (var j = 0; j < a.sourceResponseIds.length; j++) {
        if (a.sourceResponseIds[j] != b.sourceResponseIds[j]) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  List<Object?> get equalityProps => [
    id,
    sessionId,
    title,
    narrative,
    intent,
    provenance,
    lifecycle,
    createdAt,
    updatedAt,
    derivedSummary,
    ...sections,
  ];
}
