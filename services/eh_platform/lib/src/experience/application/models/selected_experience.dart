import 'package:eh_platform/src/experience/application/models/experience_action.dart';
import 'package:eh_platform/src/experience/application/models/experience_target.dart';
import 'package:eh_platform/src/experience/application/models/experience_type.dart';

/// Application-facing selected experience (not a domain aggregate).
///
/// Stable [id] values are catalog/template identities (UI.3 / HS.8), not
/// per-request UUIDs — see J.1 §14.
final class SelectedExperience {
  const SelectedExperience({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.action,
    this.rationale,
    this.target,
    this.explanationSources = const [],
  });

  final String id;
  final ExperienceType type;
  final String title;
  final String description;
  final ExperienceAction action;
  final String? rationale;
  final ExperienceTarget? target;
  final List<ExplanationSource> explanationSources;
}

/// Grounded explanation source for PF-ADR-013 explainability.
final class ExplanationSource {
  const ExplanationSource({
    required this.kind,
    required this.value,
  });

  final String kind;
  final String value;

  Map<String, Object?> toJson() => {
        'kind': kind,
        'value': value,
      };
}
