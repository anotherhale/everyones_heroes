/// Application/presentation recording session phase (HS.9).
///
/// Not a Story lifecycle state and not a domain CaptureSession aggregate.
enum RecordingSessionPhase {
  idle,
  preparing,
  ready,
  consenting,
  recording,
  paused,
  reviewing,
  persisting,
  completed,
  failed,
  cancelled,
}
