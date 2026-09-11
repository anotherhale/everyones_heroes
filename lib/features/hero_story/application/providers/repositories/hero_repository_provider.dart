import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';

final heroRepositoryProvider = Provider<HeroRepository>((ref) {
  return InMemoryHeroRepository();
});
