/// Processing state for owner-initiated AI transcription (HS.11 / HS-ADR-070).
///
/// Distinct from [StoryLifecycleStatus.processing], which means the Story was
/// submitted for publication/review — not that STT is running.
enum StoryTranscriptionJobStatus {
  /// No transcription attempt has been recorded for this Story/source.
  notStarted,

  /// Transcription is currently running for this Story/source.
  inProgress,

  /// A transcript representation was persisted successfully.
  completed,

  /// The latest attempt failed; retry is allowed.
  failed,
}
