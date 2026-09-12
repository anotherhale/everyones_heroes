import 'dart:typed_data';

import 'package:everyonesheroes/features/hero_story/domain/services/story_media_storage_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStoryMediaStorageAdapter storage;

  setUp(() {
    storage = InMemoryStoryMediaStorageAdapter();
  });

  test('store returns opaque MediaReference and retrieves bytes', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final reference = await storage.store(
      StoreStoryMediaRequest(bytes: bytes, contentType: 'audio/mp4'),
    );

    expect(reference.uri, startsWith('memory://'));
    expect(await storage.exists(reference), isTrue);
    expect(await storage.retrieve(reference), bytes);
  });

  test('empty bytes fail', () async {
    expect(
      () => storage.store(StoreStoryMediaRequest(bytes: Uint8List(0))),
      throwsA(isA<StoryMediaStorageException>()),
    );
  });

  test('missing retrieve returns null', () async {
    expect(await storage.retrieve(MediaReference('memory://missing')), isNull);
  });

  test('delete removes object', () async {
    final reference = await storage.store(
      StoreStoryMediaRequest(bytes: Uint8List.fromList([9])),
    );
    await storage.delete(reference);
    expect(await storage.exists(reference), isFalse);
  });

  test('checksum key is idempotent', () async {
    final bytes = Uint8List.fromList([7, 8, 9]);
    final first = await storage.store(
      StoreStoryMediaRequest(bytes: bytes, checksum: 'abc'),
    );
    final second = await storage.store(
      StoreStoryMediaRequest(bytes: bytes, checksum: 'abc'),
    );
    expect(first, second);
    expect(storage.objectCount, 1);
  });
}
