import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/context/current_journey_context.dart';

final currentJourneyContextProvider = Provider<CurrentJourneyContext>((ref) {
  return DefaultCurrentJourneyContext();
});
