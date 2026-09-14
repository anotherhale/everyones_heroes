import 'dart:io';
import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/local_file_story_media_storage_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late LocalFileStoryMediaStorageAdapter storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('eh-local-media-');
    storage = LocalFileStoryMediaStorageAdapter(rootDirectory: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('store writes bytes under media and retrieves them', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final reference = await storage.store(
      StoreStoryMediaRequest(
        bytes: bytes,
        contentType: 'audio/mp4',
        suggestedKey: 'captures/session-1.m4a',
      ),
    );

    expect(reference.uri, startsWith('file://'));
    expect(await storage.exists(reference), isTrue);
    expect(await storage.retrieve(reference), bytes);

    final onDisk = File(
      p.join(tempDir.path, 'media', 'captures', 'session-1.m4a'),
    );
    expect(onDisk.existsSync(), isTrue);
    expect(onDisk.readAsBytesSync(), bytes);
  });

  test('storeFromFile copies source into media root', () async {
    final source = File(p.join(tempDir.path, 'source.wav'))
      ..writeAsBytesSync([9, 8, 7]);

    final reference = await storage.storeFromFile(
      StoreStoryMediaFromFileRequest(
        filePath: source.path,
        suggestedKey: 'from-file/audio.wav',
      ),
    );

    expect(await storage.retrieve(reference), Uint8List.fromList([9, 8, 7]));
    expect(
      File(p.join(tempDir.path, 'media', 'from-file', 'audio.wav')).existsSync(),
      isTrue,
    );
  });

  test('empty bytes and missing source file fail', () async {
    expect(
      () => storage.store(StoreStoryMediaRequest(bytes: Uint8List(0))),
      throwsA(isA<StoryMediaStorageException>()),
    );
    expect(
      () => storage.storeFromFile(
        StoreStoryMediaFromFileRequest(filePath: '/no/such/file.wav'),
      ),
      throwsA(isA<StoryMediaStorageException>()),
    );
  });

  test('delete removes stored object', () async {
    final reference = await storage.store(
      StoreStoryMediaRequest(
        bytes: Uint8List.fromList([1]),
        suggestedKey: 'to-delete.bin',
      ),
    );
    await storage.delete(reference);
    expect(await storage.exists(reference), isFalse);
    expect(await storage.retrieve(reference), isNull);
  });

  test('checksum key is stable across stores', () async {
    final bytes = Uint8List.fromList([4, 5, 6]);
    final first = await storage.store(
      StoreStoryMediaRequest(bytes: bytes, checksum: 'abc123'),
    );
    final second = await storage.store(
      StoreStoryMediaRequest(bytes: bytes, checksum: 'abc123'),
    );
    expect(first.uri, second.uri);
  });
}
