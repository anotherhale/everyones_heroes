import 'package:eh_platform/src/experience/application/models/selected_experience.dart';

/// Stable presentation DTO for `GET /v1/experiences/today` (J.1 §12).
///
/// Does not expose Journey aggregate internals, BehaviorPattern domain objects,
/// repositories, events, or persistence structures.
final class TodayExperienceDto {
  const TodayExperienceDto({
    required this.experienceId,
    required this.experienceType,
    required this.title,
    required this.description,
    required this.action,
    required this.journeyId,
    this.rationale,
    this.explanation = const ExperienceExplanationDto(),
    this.target,
  });

  final String experienceId;
  final String experienceType;
  final String title;
  final String description;
  final String action;
  final String journeyId;
  final String? rationale;
  final ExperienceExplanationDto explanation;
  final Map<String, Object?>? target;

  Map<String, Object?> toJson() => {
        'experienceId': experienceId,
        'experienceType': experienceType,
        'title': title,
        'description': description,
        'action': action,
        'rationale': rationale,
        'journeyId': journeyId,
        'explanation': explanation.toJson(),
        'target': target,
      };

  factory TodayExperienceDto.fromSelection({
    required SelectedExperience experience,
    required String journeyId,
  }) {
    return TodayExperienceDto(
      experienceId: experience.id,
      experienceType: experience.type.name,
      title: experience.title,
      description: experience.description,
      action: experience.action.name,
      rationale: experience.rationale,
      journeyId: journeyId,
      explanation: ExperienceExplanationDto(
        sources: experience.explanationSources,
      ),
      target: experience.target?.toJson(),
    );
  }
}

final class ExperienceExplanationDto {
  const ExperienceExplanationDto({
    this.sources = const [],
  });

  final List<ExplanationSource> sources;

  Map<String, Object?> toJson() => {
        'sources': sources.map((s) => s.toJson()).toList(growable: false),
      };
}
