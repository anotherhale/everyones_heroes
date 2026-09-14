import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:path/path.dart' as p;

/// Durable on-device object store behind [StoryMediaStoragePort] (HS-ADR-062).
///
/// URIs use the `file://` scheme under [rootDirectory]/media`.
final class LocalFileStoryMediaStorageAdapter implements StoryMediaStoragePort {
  LocalFileStoryMediaStorageAdapter({required Directory rootDirectory})
    : _mediaRoot = Directory(p.join(rootDirectory.path, 'media'));

  final Directory _mediaRoot;

  Future<void> _ensureRoot() async {
    if (!await _mediaRoot.exists()) {
      await _mediaRoot.create(recursive: true);
    }
  }

  @override
  Future<MediaReference> store(StoreStoryMediaRequest request) async {
    if (request.bytes.isEmpty) {
      throw const StoryMediaStorageException('Cannot store empty media bytes.');
    }
    await _ensureRoot();
    final key = _resolveKey(
      suggestedKey: request.suggestedKey,
      checksum: request.checksum,
      byteLength: request.bytes.length,
    );
    final file = File(p.join(_mediaRoot.path, _safeRelativePath(key)));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(request.bytes, flush: true);
    return MediaReference(_toFileUri(file.path));
  }

  @override
  Future<MediaReference> storeFromFile(
    StoreStoryMediaFromFileRequest request,
  ) async {
    final sourcePath = request.filePath.trim();
    if (sourcePath.isEmpty) {
      throw const StoryMediaStorageException('Media file path is required.');
    }
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StoryMediaStorageException('Media file not found: $sourcePath');
    }
    final length = await source.length();
    if (length == 0) {
      throw const StoryMediaStorageException('Cannot store empty media file.');
    }

    await _ensureRoot();
    final key = _resolveKey(
      suggestedKey: request.suggestedKey,
      checksum: request.checksum,
      byteLength: length,
    );
    final destination = File(p.join(_mediaRoot.path, _safeRelativePath(key)));
    await destination.parent.create(recursive: true);

    if (p.equals(p.normalize(source.path), p.normalize(destination.path))) {
      return MediaReference(_toFileUri(destination.path));
    }
    await source.copy(destination.path);
    return MediaReference(_toFileUri(destination.path));
  }

  @override
  Future<bool> exists(MediaReference reference) async {
    final file = _fileFor(reference);
    if (file == null) {
      return false;
    }
    return file.exists();
  }

  @override
  Future<Uint8List?> retrieve(MediaReference reference) async {
    final file = _fileFor(reference);
    if (file == null || !await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<void> delete(MediaReference reference) async {
    final file = _fileFor(reference);
    if (file == null) {
      return;
    }
    if (await file.exists()) {
      await file.delete();
    }
  }

  File? _fileFor(MediaReference reference) {
    final uri = reference.uri;
    if (uri.startsWith('file://')) {
      return File(Uri.parse(uri).toFilePath());
    }
    if (p.isAbsolute(uri)) {
      return File(uri);
    }
    return null;
  }

  String _resolveKey({
    required String? suggestedKey,
    required String? checksum,
    required int byteLength,
  }) {
    final suggested = suggestedKey?.trim();
    if (suggested != null && suggested.isNotEmpty) {
      return suggested;
    }
    final checksumValue = checksum?.trim();
    if (checksumValue != null && checksumValue.isNotEmpty) {
      return 'checksum/$checksumValue';
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'obj/$byteLength-$stamp';
  }

  String _safeRelativePath(String key) {
    final normalized = key.replaceAll('\\', '/').replaceAll('..', '_');
    return normalized.startsWith('/') ? normalized.substring(1) : normalized;
  }

  String _toFileUri(String absolutePath) => Uri.file(absolutePath).toString();
}
