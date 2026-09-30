/// Lifecycle of a durable Story Builder script artifact (SB.8).
///
/// AI generation always produces [draft]. Only explicit Hero approval
/// advances to [approved]. AI-generated content is never authoritative
/// until the Hero approves (HS-ADR-006).
enum StoryBuilderScriptStatus {
  /// Generated and/or Hero-edited; not yet authoritative for materialization.
  draft,

  /// Hero-approved narrative suitable for Story materialization / recording.
  approved,
}
