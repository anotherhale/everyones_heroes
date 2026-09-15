import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/transcription_completion_store.dart';

/// Default in-memory; durable composition overrides (HS.11).
final transcriptionCompletionStoreProvider =
    Provider<TranscriptionCompletionStore>((ref) {
  return InMemoryTranscriptionCompletionStore();
});

/// Default in-memory; durable composition overrides (HS.11 / HS-ADR-070).
final storyTranscriptionJobStoreProvider =
    Provider<StoryTranscriptionJobStore>((ref) {
  return InMemoryStoryTranscriptionJobStore();
});
