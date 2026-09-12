import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_search_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_hero_search_adapter.dart';

final heroSearchPortProvider = Provider<HeroSearchPort>((ref) {
  return InMemoryHeroSearchAdapter(ref.watch(heroRepositoryProvider));
});
