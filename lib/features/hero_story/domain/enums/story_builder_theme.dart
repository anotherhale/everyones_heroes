/// What kind of story the Hero is drafting (session-local Builder vocabulary).
///
/// A session may select zero or more themes. Distinct from Discovery
/// [NarrativeTheme] entities and authoritative Story catalog themes —
/// Builder themes may later map via Understanding/apply (SB.8+), not here.
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
