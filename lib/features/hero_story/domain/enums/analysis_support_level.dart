/// Advisory categorical support for AI analysis output.
///
/// Not a probability, cross-provider confidence score, or auto-approval
/// threshold (HS-ADR-027).
enum AnalysisSupportLevel {
  unknown,
  weak,
  moderate,
  strong,
}
