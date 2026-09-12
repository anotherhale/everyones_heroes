import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Replaceable boundary for Story media bytes (HS-ADR-020).
///
/// Domain aggregates retain only [MediaReference]; adapters own bytes.
abstract interface class StoryMediaStoragePort {
  Future<MediaReference> store(StoreStoryMediaRequest request);

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

final class StoryMediaStorageException implements Exception {
  const StoryMediaStorageException(this.message);

  final String message;

  @override
  String toString() => 'StoryMediaStorageException: $message';
}
