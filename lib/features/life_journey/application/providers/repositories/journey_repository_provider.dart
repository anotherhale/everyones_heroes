import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/journey_repository.dart';
import '../../../infrastructure/repositories/in_memory_journey_repository.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return InMemoryJourneyRepository();
});
