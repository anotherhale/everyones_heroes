import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_understanding_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// JSON snapshot mapper for durable [StoryProposal] persistence (SB.9).
///
/// Follows SB.5 / HS.9 conventions: enum `.name`, ISO-8601 dates, ID `.value`.
/// Does not embed a duplicate Story Builder session.
final class StoryProposalSnapshotMapper {
  const StoryProposalSnapshotMapper._();

  static Map<String, dynamic> toJson(StoryProposal proposal) {
    return {
      'id': proposal.id.value,
      'sessionId': proposal.sessionId.value,
      'title': proposal.title?.value,
      'narrative': proposal.narrative,
      'sections': [
        for (final section in proposal.sections) _sectionToJson(section),
      ],
      'intent': _intentToJson(proposal.intent),
      'provenance': _provenanceToJson(proposal.provenance),
      'lifecycle': proposal.lifecycle.name,
      'createdAt': proposal.createdAt.toIso8601String(),
      'updatedAt': proposal.updatedAt.toIso8601String(),
      'derivedSummary': proposal.derivedSummary,
    };
  }

  static StoryProposal fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final sessionId = json['sessionId'];
      final lifecycle = json['lifecycle'];
      final createdAt = json['createdAt'];
      final updatedAt = json['updatedAt'];

      if (id is! String || id.isEmpty) {
        throw const FormatException('Missing or invalid proposal id.');
      }
      if (sessionId is! String || sessionId.isEmpty) {
        throw const FormatException('Missing or invalid sessionId.');
      }
      if (lifecycle is! String) {
        throw const FormatException('Missing or invalid lifecycle.');
      }
      if (createdAt is! String) {
        throw const FormatException('Missing or invalid createdAt.');
      }
      if (updatedAt is! String) {
        throw const FormatException('Missing or invalid updatedAt.');
      }

      final sectionsRaw = json['sections'];
      if (sectionsRaw is! List) {
        throw const FormatException('Missing or invalid sections list.');
      }

      final intentRaw = json['intent'];
      if (intentRaw != null && intentRaw is! Map) {
        throw const FormatException('Invalid intent object.');
      }

      final provenanceRaw = json['provenance'];
      if (provenanceRaw is! Map) {
        throw const FormatException('Missing or invalid provenance object.');
      }

      final titleValue = json['title'];
      if (titleValue != null && titleValue is! String) {
        throw const FormatException('Invalid title.');
      }
      final titleString = titleValue as String?;

      final narrativeRaw = json['narrative'];
      if (narrativeRaw != null && narrativeRaw is! String) {
        throw const FormatException('Invalid narrative.');
      }

      final derivedSummaryRaw = json['derivedSummary'];
      if (derivedSummaryRaw != null && derivedSummaryRaw is! String) {
        throw const FormatException('Invalid derivedSummary.');
      }

      return StoryProposal(
        id: StoryProposalId(id),
        sessionId: StoryBuilderSessionId(sessionId),
        title: titleString == null || titleString.isEmpty
            ? null
            : StoryTitle(titleString),
        narrative: narrativeRaw as String?,
        sections: [
          for (final item in sectionsRaw)
            _sectionFromJson(_asMap(item, 'section')),
        ],
        intent: _intentFromJson(
          intentRaw == null
              ? null
              : Map<String, dynamic>.from(intentRaw as Map),
        ),
        provenance: _provenanceFromJson(
          Map<String, dynamic>.from(provenanceRaw),
        ),
        lifecycle: StoryProposalLifecycleStatus.values.byName(lifecycle),
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        derivedSummary: derivedSummaryRaw as String?,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Corrupt Story Proposal snapshot: $e');
    }
  }

  static Map<String, dynamic> _sectionToJson(StoryProposalSection section) {
    return {
      'id': section.id.value,
      'narrativeRole': section.narrativeRole.name,
      'order': section.order,
      'contentOrigin': section.contentOrigin.name,
      'content': section.content,
      'sourceResponseIds': [
        for (final id in section.sourceResponseIds) id.value,
      ],
      'wasSkipped': section.wasSkipped,
    };
  }

  static StoryProposalSection _sectionFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final role = json['narrativeRole'];
    final order = json['order'];
    final origin = json['contentOrigin'];
    final wasSkipped = json['wasSkipped'];
    final content = json['content'];
    final sourceIds = json['sourceResponseIds'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Invalid section id.');
    }
    if (role is! String) {
      throw const FormatException('Invalid section narrativeRole.');
    }
    if (order is! int) {
      throw const FormatException('Invalid section order.');
    }
    if (origin is! String) {
      throw const FormatException('Invalid section contentOrigin.');
    }
    if (wasSkipped is! bool) {
      throw const FormatException('Invalid section wasSkipped.');
    }
    if (content != null && content is! String) {
      throw const FormatException('Invalid section content.');
    }
    if (sourceIds is! List) {
      throw const FormatException('Invalid section sourceResponseIds.');
    }

    return StoryProposalSection(
      id: StoryProposalSectionId(id),
      narrativeRole: StoryBuilderNarrativeRole.values.byName(role),
      order: order,
      contentOrigin: StoryProposalContentOrigin.values.byName(origin),
      content: content as String?,
      sourceResponseIds: [
        for (final item in sourceIds)
          StoryBuilderResponseId(_requireString(item, 'sourceResponseId')),
      ],
      wasSkipped: wasSkipped,
    );
  }

  static Map<String, dynamic> _intentToJson(StoryBuilderIntent intent) {
    return {
      'purpose': intent.purpose?.name,
      'themes': [for (final theme in intent.themes) theme.name],
      'themesUnsure': intent.themesUnsure,
    };
  }

  static StoryBuilderIntent _intentFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StoryBuilderIntent.empty();
    }
    final purposeRaw = json['purpose'];
    final themesRaw = json['themes'];
    final themesUnsure = json['themesUnsure'];

    if (purposeRaw != null && purposeRaw is! String) {
      throw const FormatException('Invalid intent.purpose.');
    }
    if (themesRaw != null && themesRaw is! List) {
      throw const FormatException('Invalid intent.themes.');
    }
    if (themesUnsure != null && themesUnsure is! bool) {
      throw const FormatException('Invalid intent.themesUnsure.');
    }

    return StoryBuilderIntent(
      purpose: purposeRaw == null
          ? null
          : StoryBuilderPurpose.values.byName(purposeRaw as String),
      themes: [
        for (final item in (themesRaw as List? ?? const []))
          StoryBuilderTheme.values.byName(_requireString(item, 'theme')),
      ],
      themesUnsure: themesUnsure as bool? ?? false,
    );
  }

  static Map<String, dynamic> _provenanceToJson(
    StoryProposalProvenance provenance,
  ) {
    return {
      'sessionId': provenance.sessionId.value,
      'derivationKind': provenance.derivationKind.name,
      'processingVersion': provenance.processingVersion,
      'understandingKind': provenance.understandingKind?.name,
      'understandingProcessingVersion':
          provenance.understandingProcessingVersion,
    };
  }

  static StoryProposalProvenance _provenanceFromJson(
    Map<String, dynamic> json,
  ) {
    final sessionId = json['sessionId'];
    final derivationKind = json['derivationKind'];
    final processingVersion = json['processingVersion'];
    final understandingKind = json['understandingKind'];
    final understandingProcessingVersion =
        json['understandingProcessingVersion'];

    if (sessionId is! String || sessionId.isEmpty) {
      throw const FormatException('Invalid provenance.sessionId.');
    }
    if (derivationKind is! String) {
      throw const FormatException('Invalid provenance.derivationKind.');
    }
    if (processingVersion is! String) {
      throw const FormatException('Invalid provenance.processingVersion.');
    }
    if (understandingKind != null && understandingKind is! String) {
      throw const FormatException('Invalid provenance.understandingKind.');
    }
    if (understandingProcessingVersion != null &&
        understandingProcessingVersion is! String) {
      throw const FormatException(
        'Invalid provenance.understandingProcessingVersion.',
      );
    }

    return StoryProposalProvenance(
      sessionId: StoryBuilderSessionId(sessionId),
      derivationKind: StoryProposalDerivationKind.values.byName(derivationKind),
      processingVersion: processingVersion,
      understandingKind: understandingKind == null
          ? null
          : StoryBuilderUnderstandingKind.values.byName(
              understandingKind as String,
            ),
      understandingProcessingVersion:
          understandingProcessingVersion as String?,
    );
  }

  static Map<String, dynamic> _asMap(Object? value, String label) {
    if (value is! Map) {
      throw FormatException('Invalid $label object.');
    }
    return Map<String, dynamic>.from(value);
  }

  static String _requireString(Object? value, String label) {
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $label.');
    }
    return value;
  }
}
