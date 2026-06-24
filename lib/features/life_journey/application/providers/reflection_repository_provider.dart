import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/reflection_repository.dart';
import '../../infrastructure/repositories/in_memory_reflection_repository.dart';

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  return InMemoryReflectionRepository();
});
