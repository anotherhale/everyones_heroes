import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/music_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_music_rendering_repository.dart';

/// Default in-memory repository for unit/application tests.
///
/// Production durable composition overrides with
/// [FileMusicRenderingRepository].
final musicRenderingRepositoryProvider =
    Provider<MusicRenderingRepository>((ref) {
  return InMemoryMusicRenderingRepository();
});
