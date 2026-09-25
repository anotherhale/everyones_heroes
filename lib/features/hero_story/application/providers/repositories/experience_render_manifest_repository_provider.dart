import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_experience_render_manifest_repository.dart';

/// Default in-memory repository for unit/application tests.
///
/// Production durable composition overrides with
/// [FileExperienceRenderManifestRepository].
final experienceRenderManifestRepositoryProvider =
    Provider<ExperienceRenderManifestRepository>((ref) {
  return InMemoryExperienceRenderManifestRepository();
});
