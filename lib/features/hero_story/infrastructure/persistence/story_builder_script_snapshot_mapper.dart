import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_script_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script_provenance.dart';

/// JSON snapshot mapper for durable [StoryBuilderScript] persistence (SB.8).
abstract final class StoryBuilderScriptSnapshotMapper {
  static Map<String, dynamic> toJson(StoryBuilderScript script) {
    return {
      'id': script.id.value,
      'sourceStoryBuilderSessionId': script.sourceStoryBuilderSessionId.value,
      'content': script.content,
      'language': script.language.value,
      'provenance': {
        'sessionId': script.provenance.sessionId.value,
        'processingVersion': script.provenance.processingVersion,
        'providerLabel': script.provenance.providerLabel,
        'replacedScriptId': script.provenance.replacedScriptId,
      },
      'status': script.status.name,
      'createdAt': script.createdAt.toIso8601String(),
      'updatedAt': script.updatedAt.toIso8601String(),
      'isAiGenerated': script.isAiGenerated,
      'heroEdited': script.heroEdited,
      'linkedProposalId': script.linkedProposalId?.value,
      'materializedStoryId': script.materializedStoryId?.value,
    };
  }

  static StoryBuilderScript fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final sessionId = json['sourceStoryBuilderSessionId'];
    final content = json['content'];
    final language = json['language'];
    final status = json['status'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final provenanceRaw = json['provenance'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Missing or invalid script id.');
    }
    if (sessionId is! String || sessionId.isEmpty) {
      throw const FormatException(
        'Missing or invalid sourceStoryBuilderSessionId.',
      );
    }
    if (content is! String) {
      throw const FormatException('Missing or invalid content.');
    }
    if (language is! String || language.isEmpty) {
      throw const FormatException('Missing or invalid language.');
    }
    if (status is! String) {
      throw const FormatException('Missing or invalid status.');
    }
    if (createdAt is! String || updatedAt is! String) {
      throw const FormatException('Missing or invalid timestamps.');
    }
    if (provenanceRaw is! Map) {
      throw const FormatException('Missing or invalid provenance.');
    }

    final provenanceMap = Map<String, dynamic>.from(provenanceRaw);
    final provenanceSession = provenanceMap['sessionId'];
    final processingVersion = provenanceMap['processingVersion'];
    if (provenanceSession is! String || provenanceSession.isEmpty) {
      throw const FormatException('Invalid provenance.sessionId.');
    }
    if (processingVersion is! String || processingVersion.isEmpty) {
      throw const FormatException('Invalid provenance.processingVersion.');
    }

    final linkedProposalId = json['linkedProposalId'];
    final materializedStoryId = json['materializedStoryId'];

    return StoryBuilderScript(
      id: StoryBuilderScriptId(id),
      sourceStoryBuilderSessionId: StoryBuilderSessionId(sessionId),
      content: content,
      language: LanguageCode(language),
      provenance: StoryBuilderScriptProvenance(
        sessionId: StoryBuilderSessionId(provenanceSession),
        processingVersion: processingVersion,
        providerLabel: provenanceMap['providerLabel'] as String?,
        replacedScriptId: provenanceMap['replacedScriptId'] as String?,
      ),
      status: StoryBuilderScriptStatus.values.byName(status),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      isAiGenerated: json['isAiGenerated'] as bool? ?? true,
      heroEdited: json['heroEdited'] as bool? ?? false,
      linkedProposalId: linkedProposalId is String && linkedProposalId.isNotEmpty
          ? StoryProposalId(linkedProposalId)
          : null,
      materializedStoryId:
          materializedStoryId is String && materializedStoryId.isNotEmpty
              ? StoryId(materializedStoryId)
              : null,
    );
  }
}
