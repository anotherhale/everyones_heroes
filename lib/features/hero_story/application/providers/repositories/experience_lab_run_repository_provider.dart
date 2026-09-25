import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/experience_lab_run_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_experience_lab_run_repository.dart';

/// Default in-memory repository for unit/application tests.
///
/// Production durable composition overrides with
/// [FileExperienceLabRunRepository].
final experienceLabRunRepositoryProvider =
    Provider<ExperienceLabRunRepository>((ref) {
  return InMemoryExperienceLabRunRepository();
});
