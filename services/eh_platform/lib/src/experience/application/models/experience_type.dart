/// Catalog experience kinds returned by Today's Experience (J.1).
enum ExperienceType {
  reflection,
  story,
  mission,
  coaching,
  discovery;

  static ExperienceType parse(String raw) {
    return ExperienceType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => ExperienceType.reflection,
    );
  }
}
