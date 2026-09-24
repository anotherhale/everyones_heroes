import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_captured_story_reading_repository.dart';

/// Default in-memory repository for unit/application tests.
///
/// Production durable composition overrides with
/// [FileCapturedStoryReadingRepository].
final capturedStoryReadingRepositoryProvider =
    Provider<CapturedStoryReadingRepository>((ref) {
  return InMemoryCapturedStoryReadingRepository();
});
