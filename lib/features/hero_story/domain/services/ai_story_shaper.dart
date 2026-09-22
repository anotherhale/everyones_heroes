import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_transport.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// AI-backed [StoryShaperPort] (SB.11).
///
/// Operates on a [StoryProposal] only — never mutates [StoryBuilderSession],
/// never creates a [Story], never persists. AI prose is always marked
/// [StoryProposalContentOrigin.derived]. Lifecycle is always
/// [StoryProposalLifecycleStatus.readyForReview].
final class AiStoryShaper implements StoryShaperPort {
  AiStoryShaper({
    required StoryAuthoringTransport transport,
    StoryProposalSectionId Function()? sectionIdGenerator,
    DateTime Function()? clock,
  })  : _transport = transport,
        _sectionIdGenerator =
            sectionIdGenerator ?? StoryProposalSectionId.generate,
        _clock = clock ?? DateTime.now;

  final StoryAuthoringTransport _transport;
  final StoryProposalSectionId Function() _sectionIdGenerator;
  final DateTime Function() _clock;

  @override
  Future<StoryProposal> shape(StoryProposal proposal) async {
    return shapeAt(proposal, shapedAt: _clock());
  }

  /// Shape with controllable timestamp for tests.
  Future<StoryProposal> shapeAt(
    StoryProposal proposal, {
    required DateTime shapedAt,
  }) async {
    final request = buildAuthoringRequest(proposal);
    final allowedIds = _collectAllowedSourceIds(proposal);

    final StoryAuthoringResponse response;
    try {
      response = await _transport.author(request);
    } on StoryShaperException {
      rethrow;
    } catch (e) {
      throw StoryShaperException('AI story authoring failed: $e');
    }

    return buildShapedProposal(
      source: proposal,
      response: response,
      allowedSourceIds: allowedIds,
      shapedAt: shapedAt,
      sectionIdGenerator: _sectionIdGenerator,
    );
  }

  /// Builds the minimized AI request from a proposal (no credentials / paths).
  static StoryAuthoringRequest buildAuthoringRequest(StoryProposal proposal) {
    return StoryAuthoringRequest(
      purpose: proposal.intent.purpose,
      themes: List.of(proposal.intent.themes),
      themesUnsure: proposal.intent.themesUnsure,
      title: proposal.title?.value,
      summary: proposal.narrative,
      understandingSummary: proposal.derivedSummary,
      sections: [
        for (final section in proposal.sections)
          StoryAuthoringSectionInput(
            role: section.narrativeRole,
            content: section.content,
            sourceResponseIds: List.of(section.sourceResponseIds),
            contentOrigin: section.contentOrigin,
            wasSkipped: section.wasSkipped,
          ),
      ],
    );
  }

  /// Validates AI output and constructs a new proposal. Never trusts AI for
  /// lifecycle or contentOrigin.
  static StoryProposal buildShapedProposal({
    required StoryProposal source,
    required StoryAuthoringResponse response,
    required Set<String> allowedSourceIds,
    required DateTime shapedAt,
    StoryProposalSectionId Function()? sectionIdGenerator,
  }) {
    final idGen = sectionIdGenerator ?? StoryProposalSectionId.generate;

    if (response.sections.isEmpty) {
      throw const StoryShaperException(
        'AI story authoring returned no sections.',
      );
    }

    final shapedSections = <StoryProposalSection>[];
    for (var i = 0; i < response.sections.length; i++) {
      final out = response.sections[i];
      _validateRole(out.role);
      final sourceIds = _validateAndSanitizeSourceIds(
        out.sourceResponseIds,
        allowedSourceIds,
      );

      final content = out.content?.trim();
      final hasContent = content != null && content.isNotEmpty;

      // Application — not the AI — decides content origin.
      // AI-produced prose is always derived (never heroAuthored).
      shapedSections.add(
        StoryProposalSection(
          id: idGen(),
          narrativeRole: out.role,
          order: i,
          contentOrigin: StoryProposalContentOrigin.derived,
          content: hasContent ? content : null,
          sourceResponseIds: sourceIds,
          wasSkipped: false,
        ),
      );
    }

    // Re-number to contiguous order 0..n-1 (already i, but rebuild narrative).
    final narrative = _assembleNarrative(shapedSections);
    final title = _resolveTitle(response.title, source.title);
    final summary = _resolveSummary(response.summary, source.derivedSummary);

    // AI must never control lifecycle — always readyForReview.
    return StoryProposal(
      id: source.id,
      sessionId: source.sessionId,
      title: title,
      narrative: narrative,
      sections: shapedSections,
      intent: source.intent,
      provenance: StoryProposalProvenance(
        sessionId: source.provenance.sessionId,
        derivationKind: StoryProposalDerivationKind.aiShaped,
        processingVersion: StoryProposal.aiShapedProcessingVersion,
        understandingKind: source.provenance.understandingKind,
        understandingProcessingVersion:
            source.provenance.understandingProcessingVersion,
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: source.createdAt,
      updatedAt: shapedAt,
      derivedSummary: summary,
    );
  }

  static Set<String> _collectAllowedSourceIds(StoryProposal proposal) {
    final ids = <String>{};
    for (final section in proposal.sections) {
      for (final id in section.sourceResponseIds) {
        ids.add(id.value);
      }
    }
    return ids;
  }

  static void _validateRole(StoryBuilderNarrativeRole role) {
    // Enum typing already constrains to SB.4 roles at parse time; keep explicit.
    if (!StoryBuilderNarrativeRole.values.contains(role)) {
      throw StoryShaperException(
        'AI story authoring returned unknown narrative role: $role',
      );
    }
  }

  static List<StoryBuilderResponseId> _validateAndSanitizeSourceIds(
    List<StoryBuilderResponseId> ids,
    Set<String> allowed,
  ) {
    if (ids.isEmpty) {
      throw const StoryShaperException(
        'AI story authoring section is missing sourceResponseIds.',
      );
    }
    final result = <StoryBuilderResponseId>[];
    final seen = <String>{};
    for (final id in ids) {
      final value = id.value.trim();
      if (value.isEmpty) {
        throw const StoryShaperException(
          'AI story authoring returned a malformed sourceResponseId.',
        );
      }
      if (!allowed.contains(value)) {
        throw StoryShaperException(
          'AI story authoring referenced unknown sourceResponseId: $value',
        );
      }
      if (seen.add(value)) {
        result.add(StoryBuilderResponseId(value));
      }
    }
    return result;
  }

  static String? _assembleNarrative(List<StoryProposalSection> sections) {
    final parts = <String>[];
    for (final section in sections) {
      final content = section.content?.trim();
      if (content == null || content.isEmpty) continue;
      parts.add(content);
    }
    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  static StoryTitle? _resolveTitle(String? aiTitle, StoryTitle? existing) {
    final trimmed = aiTitle?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      try {
        return StoryTitle(trimmed);
      } on ArgumentError catch (e) {
        throw StoryShaperException('AI story authoring title invalid: $e');
      }
    }
    return existing;
  }

  static String? _resolveSummary(String? aiSummary, String? existing) {
    final trimmed = aiSummary?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      if (trimmed.length > StoryProposal.maxDerivedSummaryLength) {
        throw const StoryShaperException(
          'AI story authoring summary exceeds maximum length.',
        );
      }
      return trimmed;
    }
    return existing;
  }
}
