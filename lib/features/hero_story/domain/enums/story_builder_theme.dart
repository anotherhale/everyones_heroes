/// What kind of story the Hero is drafting (session-local Builder vocabulary).
///
/// A session may select zero or more themes. Distinct from Discovery
/// NarrativeTheme entities — Builder themes are authoring intent, not catalog
/// ownership. Translation to Discovery [NarrativeThemeId] happens at the
/// application boundary (HS.FG.2 bridge), not inside this enum.
enum StoryBuilderTheme {
  overcomingAdversity,
  courage,
  service,
  leadership,
  loss,
  failure,
  transformation,
  perseverance,
  secondChances,
  sacrifice,
  family,
  discovery,
  purpose,
  love,
}
