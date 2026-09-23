import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_action.dart';
import 'package:everyonesheroes/features/life_journey/application/models/experience_target.dart';

/// Thin Flutter mapping of platform `GET /v1/experiences/today` DTO (J.1).
final class TodayExperienceDto {
  const TodayExperienceDto({
    required this.experienceId,
    required this.experienceType,
    required this.title,
    required this.description,
    required this.action,
    required this.journeyId,
    this.rationale,
    this.explanationSources = const [],
    this.storyTargetId,
  });

  final String experienceId;
  final String experienceType;
  final String title;
  final String description;
  final String action;
  final String journeyId;
  final String? rationale;
  final List<ExplanationSourceDto> explanationSources;
  final String? storyTargetId;

  factory TodayExperienceDto.fromJson(Map<String, dynamic> json) {
    final explanation = json['explanation'];
    final sourcesRaw = explanation is Map ? explanation['sources'] : null;
    final sources = <ExplanationSourceDto>[];
    if (sourcesRaw is List) {
      for (final item in sourcesRaw) {
        if (item is Map) {
          sources.add(
            ExplanationSourceDto(
              kind: item['kind']?.toString() ?? '',
              value: item['value']?.toString() ?? '',
            ),
          );
        }
      }
    }

    String? storyTargetId;
    final target = json['target'];
    if (target is Map && target['kind']?.toString() == 'story') {
      storyTargetId = target['storyId']?.toString();
    }

    return TodayExperienceDto(
      experienceId: json['experienceId']?.toString() ?? '',
      experienceType: json['experienceType']?.toString() ?? 'reflection',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      action: json['action']?.toString() ?? 'begin',
      journeyId: json['journeyId']?.toString() ?? '',
      rationale: json['rationale']?.toString(),
      explanationSources: sources,
      storyTargetId: storyTargetId,
    );
  }

  AdaptiveExperience toAdaptiveExperience() {
    final type = ExperienceType.values.firstWhere(
      (value) => value.name == experienceType,
      orElse: () => ExperienceType.reflection,
    );
    final experienceAction = ExperienceAction.values.firstWhere(
      (value) => value.name == action,
      orElse: () => ExperienceAction.begin,
    );

    return AdaptiveExperience(
      id: experienceId,
      type: type,
      title: title,
      description: description,
      action: experienceAction,
      rationale: rationale,
      target: storyTargetId == null
          ? null
          : StoryExperienceTarget(storyId: StoryId(storyTargetId!)),
    );
  }
}

final class ExplanationSourceDto {
  const ExplanationSourceDto({
    required this.kind,
    required this.value,
  });

  final String kind;
  final String value;
}
