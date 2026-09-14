import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Deterministic in-memory media store for tests and local development.
///
/// Implements [storeFromFile] by reading bytes into memory (acceptable for
/// tests; production uses [LocalFileStoryMediaStorageAdapter]).
final class InMemoryStoryMediaStorageAdapter implements StoryMediaStoragePort {
  InMemoryStoryMediaStorageAdapter({this.uriScheme = 'memory'});

  final String uriScheme;
  final Map<String, Uint8List> _objects = {};
  int _sequence = 0;

  int get objectCount => _objects.length;

  UnmodifiableMapView<String, Uint8List> get snapshot =>
      UnmodifiableMapView(_objects);

  @override
  Future<MediaReference> store(StoreStoryMediaRequest request) async {
    if (request.bytes.isEmpty) {
      throw const StoryMediaStorageException('Cannot store empty media bytes.');
    }

    final key = _resolveKey(
      suggestedKey: request.suggestedKey,
      checksum: request.checksum,
      byteLength: request.bytes.length,
      hashSeed: request.bytes,
    );
    final uri = '$uriScheme://$key';
    _objects[uri] = Uint8List.fromList(request.bytes);
    return MediaReference(uri);
  }

  @override
  Future<MediaReference> storeFromFile(
    StoreStoryMediaFromFileRequest request,
  ) async {
    final path = request.filePath.trim();
    if (path.isEmpty) {
      throw const StoryMediaStorageException('Media file path is required.');
    }
    final file = File(path);
    if (!await file.exists()) {
      throw StoryMediaStorageException('Media file not found: $path');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const StoryMediaStorageException('Cannot store empty media file.');
    }
    return store(
      StoreStoryMediaRequest(
        bytes: bytes,
        contentType: request.contentType,
        checksum: request.checksum,
        suggestedKey: request.suggestedKey,
      ),
    );
  }

  @override
  Future<bool> exists(MediaReference reference) async {
    return _objects.containsKey(reference.uri);
  }

  @override
  Future<Uint8List?> retrieve(MediaReference reference) async {
    final bytes = _objects[reference.uri];
    if (bytes == null) {
      return null;
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> delete(MediaReference reference) async {
    _objects.remove(reference.uri);
  }

  String _resolveKey({
    required String? suggestedKey,
    required String? checksum,
    required int byteLength,
    required List<int> hashSeed,
  }) {
    final suggested = suggestedKey?.trim();
    if (suggested != null && suggested.isNotEmpty) {
      return suggested;
    }

    final checksumValue = checksum?.trim();
    if (checksumValue != null && checksumValue.isNotEmpty) {
      return 'checksum/$checksumValue';
    }

    var hash = 0;
    for (final b in hashSeed) {
      hash = (hash * 31 + b) & 0x7fffffff;
    }
    _sequence += 1;
    return 'obj/$byteLength-$hash-$_sequence';
  }
}
