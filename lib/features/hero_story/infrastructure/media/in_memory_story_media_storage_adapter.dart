import 'dart:collection';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Deterministic in-memory media store for tests and local development.
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

    final key = _resolveKey(request);
    final uri = '$uriScheme://$key';
    _objects[uri] = Uint8List.fromList(request.bytes);
    return MediaReference(uri);
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

  String _resolveKey(StoreStoryMediaRequest request) {
    final suggested = request.suggestedKey?.trim();
    if (suggested != null && suggested.isNotEmpty) {
      return suggested;
    }

    final checksum = request.checksum?.trim();
    if (checksum != null && checksum.isNotEmpty) {
      return 'checksum/$checksum';
    }

    var hash = 0;
    for (final b in request.bytes) {
      hash = (hash * 31 + b) & 0x7fffffff;
    }
    _sequence += 1;
    return 'obj/${request.bytes.length}-$hash-$_sequence';
  }
}
