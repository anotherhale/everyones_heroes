import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/discovery/domain/repositories/influence_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';

final influenceRepositoryProvider = Provider<InfluenceRepository>((ref) {
  return InMemoryInfluenceRepository.withReferenceCatalog();
});
