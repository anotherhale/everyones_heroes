/// Presentation-facing action for Today's Experience (J.1).
enum ExperienceAction {
  begin;

  static ExperienceAction parse(String raw) {
    return ExperienceAction.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => ExperienceAction.begin,
    );
  }
}
