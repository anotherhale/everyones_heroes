import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Replaceable boundary for Story media bytes (HS-ADR-020 / HS-ADR-062).
///
/// Domain aggregates retain only [MediaReference]; adapters own bytes.
abstract interface class StoryMediaStoragePort {
  Future<MediaReference> store(StoreStoryMediaRequest request);

  /// Stores media from a local file path without requiring the caller to hold
  /// the full byte array in memory (HS.9 large-recording support).
  Future<MediaReference> storeFromFile(StoreStoryMediaFromFileRequest request);

  Future<bool> exists(MediaReference reference);

  Future<Uint8List?> retrieve(MediaReference reference);

  Future<void> delete(MediaReference reference);
}

final class StoreStoryMediaRequest {
  const StoreStoryMediaRequest({
    required this.bytes,
    this.contentType,
    this.checksum,
    this.suggestedKey,
  });

  final Uint8List bytes;
  final String? contentType;
  final String? checksum;
  final String? suggestedKey;
}

/// File-backed store request (HS.9 / HS-ADR-062).
final class StoreStoryMediaFromFileRequest {
  const StoreStoryMediaFromFileRequest({
    required this.filePath,
    this.contentType,
    this.checksum,
    this.suggestedKey,
  });

  final String filePath;
  final String? contentType;
  final String? checksum;
  final String? suggestedKey;
}

final class StoryMediaStorageException implements Exception {
  const StoryMediaStorageException(this.message);

  final String message;

  @override
  String toString() => 'StoryMediaStorageException: $message';
}
