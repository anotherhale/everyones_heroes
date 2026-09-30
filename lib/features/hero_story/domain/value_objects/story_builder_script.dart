import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_script_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script_provenance.dart';

/// Durable narrative script derived from a Story Builder session (SB.8).
///
/// Not a [Story]. Not a recording transcript. Not a [StoryRepresentation]
/// (those attach to an existing Story). This artifact exists so the Hero can
/// review/edit/approve a complete first-person narrative **before** Story
/// materialization, and so approval survives Create Story failures.
///
/// After materialization, the approved content becomes Story narrative (and
/// may later seed a `script` [StoryRepresentation]). Recording / TTS paths
/// must consume approved content — never invent prose here.
final class StoryBuilderScript extends ValueObject {
  StoryBuilderScript({
    required this.id,
    required StoryBuilderSessionId sourceStoryBuilderSessionId,
    required String content,
    required this.language,
    required this.provenance,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isAiGenerated = true,
    this.heroEdited = false,
    this.linkedProposalId,
    this.materializedStoryId,
  })  : sourceStoryBuilderSessionId = sourceStoryBuilderSessionId,
        content = content.trim() {
    if (this.content.isEmpty) {
      throw ArgumentError('StoryBuilderScript content cannot be blank.');
    }
    if (provenance.sessionId != sourceStoryBuilderSessionId) {
      throw ArgumentError(
        'StoryBuilderScript.sourceStoryBuilderSessionId must match '
        'provenance.sessionId.',
      );
    }
    if (materializedStoryId != null &&
        status != StoryBuilderScriptStatus.approved) {
      throw ArgumentError(
        'materializedStoryId may only be set on an approved script.',
      );
    }
  }

  /// Processing version for AI-generated Story Builder scripts.
  static const String aiProcessingVersion = 'sb8.script.ai.v1';

  final StoryBuilderScriptId id;

  /// Canonical session whose Hero answers grounded this script.
  final StoryBuilderSessionId sourceStoryBuilderSessionId;

  /// Full first-person narrative suitable to read aloud / record / narrate.
  final String content;

  final LanguageCode language;
  final StoryBuilderScriptProvenance provenance;
  final StoryBuilderScriptStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True when content originated from AI transformation (still non-authoritative
  /// until [approved]).
  final bool isAiGenerated;

  /// True after the Hero edits content in place.
  final bool heroEdited;

  /// Proposal built from this approved script for SB.13 materialization.
  final StoryProposalId? linkedProposalId;

  /// Canonical Story created from this approved script, if any.
  final StoryId? materializedStoryId;

  bool get isDraft => status == StoryBuilderScriptStatus.draft;

  bool get isApproved => status == StoryBuilderScriptStatus.approved;

  bool get isMaterialized => materializedStoryId != null;

  /// In-place Hero edit. Clears approval — AI drafts are never silently
  /// re-approved after edits.
  StoryBuilderScript withEditedContent(String newContent, {DateTime? at}) {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Edited script content cannot be blank.');
    }
    final now = at ?? DateTime.now();
    return StoryBuilderScript(
      id: id,
      sourceStoryBuilderSessionId: sourceStoryBuilderSessionId,
      content: trimmed,
      language: language,
      provenance: provenance,
      status: StoryBuilderScriptStatus.draft,
      createdAt: createdAt,
      updatedAt: now,
      isAiGenerated: isAiGenerated,
      heroEdited: true,
      linkedProposalId: null,
      materializedStoryId: null,
    );
  }

  /// Explicit Hero approval — the only path to [approved].
  StoryBuilderScript approve({DateTime? at}) {
    if (status == StoryBuilderScriptStatus.approved) {
      return this;
    }
    if (content.trim().isEmpty) {
      throw StateError('Cannot approve a blank Story Builder script.');
    }
    final now = at ?? DateTime.now();
    return StoryBuilderScript(
      id: id,
      sourceStoryBuilderSessionId: sourceStoryBuilderSessionId,
      content: content,
      language: language,
      provenance: provenance,
      status: StoryBuilderScriptStatus.approved,
      createdAt: createdAt,
      updatedAt: now,
      isAiGenerated: isAiGenerated,
      heroEdited: heroEdited,
      linkedProposalId: linkedProposalId,
      materializedStoryId: materializedStoryId,
    );
  }

  StoryBuilderScript withLinkedProposal(
    StoryProposalId proposalId, {
    DateTime? at,
  }) {
    if (status != StoryBuilderScriptStatus.approved) {
      throw StateError(
        'Only an approved script can be linked to a StoryProposal.',
      );
    }
    return StoryBuilderScript(
      id: id,
      sourceStoryBuilderSessionId: sourceStoryBuilderSessionId,
      content: content,
      language: language,
      provenance: provenance,
      status: status,
      createdAt: createdAt,
      updatedAt: at ?? DateTime.now(),
      isAiGenerated: isAiGenerated,
      heroEdited: heroEdited,
      linkedProposalId: proposalId,
      materializedStoryId: materializedStoryId,
    );
  }

  /// Records successful Story materialization. Does not revoke approval.
  StoryBuilderScript recordMaterializedStory(
    StoryId storyId, {
    DateTime? at,
  }) {
    if (status != StoryBuilderScriptStatus.approved) {
      throw StateError(
        'Only an approved script can record a materialized Story.',
      );
    }
    return StoryBuilderScript(
      id: id,
      sourceStoryBuilderSessionId: sourceStoryBuilderSessionId,
      content: content,
      language: language,
      provenance: provenance,
      status: status,
      createdAt: createdAt,
      updatedAt: at ?? DateTime.now(),
      isAiGenerated: isAiGenerated,
      heroEdited: heroEdited,
      linkedProposalId: linkedProposalId,
      materializedStoryId: storyId,
    );
  }

  @override
  List<Object?> get equalityProps => [
        id,
        sourceStoryBuilderSessionId,
        content,
        language,
        provenance,
        status,
        createdAt,
        updatedAt,
        isAiGenerated,
        heroEdited,
        linkedProposalId,
        materializedStoryId,
      ];
}
