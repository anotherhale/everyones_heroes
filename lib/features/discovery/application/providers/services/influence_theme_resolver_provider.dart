import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/discovery/application/providers/repositories/influence_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/domain/services/influence_theme_resolver.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/services/in_memory_influence_theme_resolver.dart';

final influenceThemeResolverProvider = Provider<InfluenceThemeResolver>((ref) {
  return InMemoryInfluenceThemeResolver(
    influenceRepository: ref.watch(influenceRepositoryProvider),
  );
});
