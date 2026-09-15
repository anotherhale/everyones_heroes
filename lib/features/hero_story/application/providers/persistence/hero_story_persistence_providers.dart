import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:everyonesheroes/features/hero_story/application/capture/capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/application/transcription/story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/application/understanding/transcription_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/capture/file_capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/local_file_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/transcription/file_story_transcription_job_store.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/transcription/file_transcription_completion_store.dart';

/// Root directory for durable Hero & Story local persistence (HS.9).
///
/// Resolved asynchronously at app composition; tests override repositories
/// directly and do not need this provider.
final heroStoryStorageRootProvider = FutureProvider<Directory>((ref) async {
  final docs = await getApplicationDocumentsDirectory();
  final root = Directory(p.join(docs.path, 'hero_story'));
  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  return root;
});

/// Temp directory for in-progress device recordings (not durable media).
final heroStoryRecordingTempProvider = FutureProvider<Directory>((ref) async {
  final cache = await getTemporaryDirectory();
  final temp = Directory(p.join(cache.path, 'hero_story_recording'));
  if (!await temp.exists()) {
    await temp.create(recursive: true);
  }
  return temp;
});

/// Manifest directory for recording session recovery.
final heroStoryRecordingManifestProvider = FutureProvider<Directory>((
  ref,
) async {
  final root = await ref.watch(heroStoryStorageRootProvider.future);
  final dir = Directory(p.join(root.path, 'recording_sessions'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
});

/// Builds durable HS.9 / HS.11 adapters from a resolved storage root.
final class HeroStoryDurablePersistence {
  HeroStoryDurablePersistence(this.rootDirectory)
    : heroRepository = FileHeroRepository(rootDirectory: rootDirectory),
      storyRepository = FileStoryRepository(rootDirectory: rootDirectory),
      mediaStorage = LocalFileStoryMediaStorageAdapter(
        rootDirectory: rootDirectory,
      ),
      transcriptionJobStore = FileStoryTranscriptionJobStore(
        rootDirectory: rootDirectory,
      ) {
    captureCompletionStore = FileCaptureCompletionStore(
      rootDirectory: rootDirectory,
      storyRepository: storyRepository,
    );
    transcriptionCompletionStore = FileTranscriptionCompletionStore(
      rootDirectory: rootDirectory,
      storyRepository: storyRepository,
    );
  }

  final Directory rootDirectory;
  final HeroRepository heroRepository;
  final StoryRepository storyRepository;
  final StoryMediaStoragePort mediaStorage;
  late final CaptureCompletionStore captureCompletionStore;
  late final TranscriptionCompletionStore transcriptionCompletionStore;
  final StoryTranscriptionJobStore transcriptionJobStore;
}
