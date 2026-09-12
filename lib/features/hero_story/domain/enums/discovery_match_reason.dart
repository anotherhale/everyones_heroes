/// Non-personalized catalog match reason codes (HS.6 soft gate D8).
///
/// Explains which filter dimension contributed to a discovery match.
/// Does not encode personalization, ranking, or user-understanding scores.
enum DiscoveryMatchReason {
  text,
  hero,
  experienceArea,
  subject,
  challenge,
  narrativeTheme,
  outcome,
  emotionalCharacter,
  audience,
  geography,
  spirituality,
  suitability,
  format,
  duration,
  originalLanguage,
  availableLanguage,
}
