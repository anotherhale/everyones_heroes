import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/emotional_character.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/religious_tradition.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_audience.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_challenge.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_outcome.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_representation_format.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_subject.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/content_suitability.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/provenance_step.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/spirituality_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_consent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_geography.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// JSON snapshot mapper for durable local [Story] persistence (HS.9).
///
/// Uses the public [Story] constructor for reconstitution (no domain events).
final class StorySnapshotMapper {
  const StorySnapshotMapper._();

  static Map<String, dynamic> toJson(Story story) {
    return {
      'id': story.id.value,
      'heroId': story.heroId.value,
      'title': story.title.value,
      'narrative': {
        'value': story.narrative.value,
        'isProvisional': story.narrative.isProvisional,
      },
      'originalLanguage': story.originalLanguage.value,
      'lifecycleStatus': story.lifecycleStatus.name,
      'visibility': story.visibility.name,
      'classification': _classificationToJson(story.classification),
      'contentSuitability': _suitabilityToJson(story.contentSuitability),
      'spirituality': _spiritualityToJson(story.spirituality),
      'provenance': _provenanceToJson(story.provenance),
      'consent': _consentToJson(story.consent),
      'representations': [
        for (final representation in story.representations)
          _representationToJson(representation),
      ],
      'createdAt': story.createdAt.toIso8601String(),
      'updatedAt': story.updatedAt.toIso8601String(),
    };
  }

  static Story fromJson(Map<String, dynamic> json) {
    final narrativeJson = Map<String, dynamic>.from(json['narrative'] as Map);
    final representationsRaw = json['representations'] as List? ?? const [];

    return Story(
      id: StoryId(json['id'] as String),
      heroId: HeroId(json['heroId'] as String),
      title: StoryTitle(json['title'] as String),
      narrative: StoryNarrative(
        narrativeJson['value'] as String,
        isProvisional: narrativeJson['isProvisional'] as bool? ?? false,
      ),
      originalLanguage: LanguageCode(json['originalLanguage'] as String),
      lifecycleStatus: StoryLifecycleStatus.values.byName(
        json['lifecycleStatus'] as String,
      ),
      visibility: StoryVisibility.values.byName(json['visibility'] as String),
      classification: _classificationFromJson(
        Map<String, dynamic>.from(json['classification'] as Map? ?? const {}),
      ),
      contentSuitability: _suitabilityFromJson(
        Map<String, dynamic>.from(
          json['contentSuitability'] as Map? ?? const {},
        ),
      ),
      spirituality: _spiritualityFromJson(
        Map<String, dynamic>.from(json['spirituality'] as Map? ?? const {}),
      ),
      provenance: _provenanceFromJson(
        Map<String, dynamic>.from(json['provenance'] as Map? ?? const {}),
      ),
      consent: _consentFromJson(
        Map<String, dynamic>.from(json['consent'] as Map? ?? const {}),
      ),
      representations: [
        for (final item in representationsRaw)
          _representationFromJson(Map<String, dynamic>.from(item as Map)),
      ],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static Map<String, dynamic> _classificationToJson(
    StoryClassification classification,
  ) {
    return {
      'subjects': [
        for (final subject in classification.subjects) subject.name,
      ],
      'challenges': [
        for (final challenge in classification.challenges) challenge.name,
      ],
      'outcomes': [
        for (final outcome in classification.outcomes) outcome.name,
      ],
      'emotionalCharacters': [
        for (final character in classification.emotionalCharacters)
          character.name,
      ],
      'narrativeThemeIds': [
        for (final themeId in classification.narrativeThemeIds) themeId.value,
      ],
      'audience': classification.audience?.name,
      'geography': classification.geography == null
          ? null
          : {
              'country': classification.geography!.country,
              'region': classification.geography!.region,
              'city': classification.geography!.city,
              'culturalContext': classification.geography!.culturalContext,
            },
    };
  }

  static StoryClassification _classificationFromJson(
    Map<String, dynamic> json,
  ) {
    final geographyJson = json['geography'] == null
        ? null
        : Map<String, dynamic>.from(json['geography'] as Map);

    return StoryClassification(
      subjects: [
        for (final name in json['subjects'] as List? ?? const [])
          StorySubject.values.byName(name as String),
      ],
      challenges: [
        for (final name in json['challenges'] as List? ?? const [])
          StoryChallenge.values.byName(name as String),
      ],
      outcomes: [
        for (final name in json['outcomes'] as List? ?? const [])
          StoryOutcome.values.byName(name as String),
      ],
      emotionalCharacters: [
        for (final name in json['emotionalCharacters'] as List? ?? const [])
          EmotionalCharacter.values.byName(name as String),
      ],
      narrativeThemeIds: [
        for (final id in json['narrativeThemeIds'] as List? ?? const [])
          NarrativeThemeId(id as String),
      ],
      audience: json['audience'] == null
          ? null
          : StoryAudience.values.byName(json['audience'] as String),
      geography: geographyJson == null
          ? null
          : StoryGeography(
              country: geographyJson['country'] as String?,
              region: geographyJson['region'] as String?,
              city: geographyJson['city'] as String?,
              culturalContext: geographyJson['culturalContext'] as String?,
            ),
    );
  }

  static Map<String, dynamic> _suitabilityToJson(
    ContentSuitability suitability,
  ) {
    return {
      'profanity': suitability.profanity.name,
      'violence': suitability.violence.name,
      'sexualContent': suitability.sexualContent.name,
      'substanceUse': suitability.substanceUse.name,
      'disturbingContent': suitability.disturbingContent.name,
    };
  }

  static ContentSuitability _suitabilityFromJson(Map<String, dynamic> json) {
    SuitabilityLevel level(String key) {
      final raw = json[key] as String?;
      if (raw == null) {
        return SuitabilityLevel.none;
      }
      return SuitabilityLevel.values.byName(raw);
    }

    return ContentSuitability(
      profanity: level('profanity'),
      violence: level('violence'),
      sexualContent: level('sexualContent'),
      substanceUse: level('substanceUse'),
      disturbingContent: level('disturbingContent'),
    );
  }

  static Map<String, dynamic> _spiritualityToJson(
    SpiritualityClassification spirituality,
  ) {
    return {
      'category': spirituality.category.name,
      'tradition': spirituality.tradition?.name,
    };
  }

  static SpiritualityClassification _spiritualityFromJson(
    Map<String, dynamic> json,
  ) {
    if (json.isEmpty) {
      return SpiritualityClassification.nonSpiritual;
    }

    return SpiritualityClassification(
      category: SpiritualityCategory.values.byName(json['category'] as String),
      tradition: json['tradition'] == null
          ? null
          : ReligiousTradition.values.byName(json['tradition'] as String),
    );
  }

  static Map<String, dynamic> _provenanceToJson(StoryProvenance provenance) {
    return {
      'originalSourceDescription': provenance.originalSourceDescription,
      'steps': [
        for (final step in provenance.steps) _provenanceStepToJson(step),
      ],
    };
  }

  static StoryProvenance _provenanceFromJson(Map<String, dynamic> json) {
    final stepsRaw = json['steps'] as List? ?? const [];
    return StoryProvenance(
      originalSourceDescription: json['originalSourceDescription'] as String?,
      steps: [
        for (final step in stepsRaw)
          _provenanceStepFromJson(Map<String, dynamic>.from(step as Map)),
      ],
    );
  }

  static Map<String, dynamic> _provenanceStepToJson(ProvenanceStep step) {
    return {
      'transformationType': step.transformationType.name,
      'producedRepresentationId': step.producedRepresentationId.value,
      'sourceRepresentationId': step.sourceRepresentationId?.value,
      'occurredAt': step.occurredAt.toIso8601String(),
      'isAiAssisted': step.isAiAssisted,
      'note': step.note,
    };
  }

  static ProvenanceStep _provenanceStepFromJson(Map<String, dynamic> json) {
    return ProvenanceStep(
      transformationType: StoryTransformationType.values.byName(
        json['transformationType'] as String,
      ),
      producedRepresentationId: StoryRepresentationId(
        json['producedRepresentationId'] as String,
      ),
      sourceRepresentationId: json['sourceRepresentationId'] == null
          ? null
          : StoryRepresentationId(json['sourceRepresentationId'] as String),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      isAiAssisted: json['isAiAssisted'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  static Map<String, dynamic> _consentToJson(StoryConsent consent) {
    return {
      'recordedAt': consent.recordedAt?.toIso8601String(),
      'processingApprovedAt': consent.processingApprovedAt?.toIso8601String(),
      'publicationApprovedAt': consent.publicationApprovedAt?.toIso8601String(),
      'aiTransformationApprovedAt':
          consent.aiTransformationApprovedAt?.toIso8601String(),
    };
  }

  static StoryConsent _consentFromJson(Map<String, dynamic> json) {
    DateTime? parseOptional(String key) {
      final raw = json[key] as String?;
      return raw == null ? null : DateTime.parse(raw);
    }

    return StoryConsent(
      recordedAt: parseOptional('recordedAt'),
      processingApprovedAt: parseOptional('processingApprovedAt'),
      publicationApprovedAt: parseOptional('publicationApprovedAt'),
      aiTransformationApprovedAt: parseOptional('aiTransformationApprovedAt'),
    );
  }

  static Map<String, dynamic> _representationToJson(
    StoryRepresentation representation,
  ) {
    return {
      'id': representation.id.value,
      'language': representation.language.value,
      'format': representation.format.name,
      'origin': representation.origin.name,
      'mediaReference': representation.mediaReference?.uri,
      'textContent': representation.textContent,
      'sourceRepresentationId': representation.sourceRepresentationId?.value,
      'durationMs': representation.duration?.inMilliseconds,
      'isAiGenerated': representation.isAiGenerated,
      'isApproved': representation.isApproved,
    };
  }

  static StoryRepresentation _representationFromJson(
    Map<String, dynamic> json,
  ) {
    final durationMs = json['durationMs'] as int?;
    return StoryRepresentation(
      id: StoryRepresentationId(json['id'] as String),
      language: LanguageCode(json['language'] as String),
      format: StoryRepresentationFormat.values.byName(json['format'] as String),
      origin: RepresentationOrigin.values.byName(json['origin'] as String),
      mediaReference: json['mediaReference'] == null
          ? null
          : MediaReference(json['mediaReference'] as String),
      textContent: json['textContent'] as String?,
      sourceRepresentationId: json['sourceRepresentationId'] == null
          ? null
          : StoryRepresentationId(json['sourceRepresentationId'] as String),
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
    );
  }
}
