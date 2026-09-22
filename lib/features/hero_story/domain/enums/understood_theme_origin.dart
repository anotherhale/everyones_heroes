/// Where an understood theme came from (SB.8).
enum UnderstoodThemeOrigin {
  /// Declared on the session intent (SB.2) — not inferred from responses.
  sessionIntent,

  /// Derived from Hero-authored response material.
  derivedFromResponses,
}
