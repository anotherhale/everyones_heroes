/// Attribution of a selected Story's matched narrative themes to understanding
/// sources used for Today's Experience explanation (D.9).
///
/// Application-level explanation metadata only — not a domain aggregate,
/// not persistent, and not part of DiscoveryProfile / Reflection / Journey.
///
/// Ranking does not consume this type. Platform Today provenance parity is
/// deferred.
enum NarrativeThemeMatchSource {
  /// Matched themes intersect Inspiration (DiscoveryProfile) themes only.
  inspiration,

  /// Matched themes intersect Reflection-derived themes only.
  reflection,

  /// Matched themes intersect both Inspiration and Reflection themes.
  mixed,

  /// Matched themes cannot be attributed to Inspiration or Reflection.
  unknown,
}
