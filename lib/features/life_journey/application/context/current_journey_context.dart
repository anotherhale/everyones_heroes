import 'package:everyonesheroes/core/ids/journey_id.dart';

abstract interface class CurrentJourneyContext {
  JourneyId? get currentJourneyId;

  void setCurrentJourney(JourneyId journeyId);

  void clear();
}

final class DefaultCurrentJourneyContext implements CurrentJourneyContext {
  JourneyId? _currentJourneyId;

  @override
  JourneyId? get currentJourneyId => _currentJourneyId;

  @override
  void setCurrentJourney(JourneyId journeyId) {
    _currentJourneyId = journeyId;
  }

  @override
  void clear() {
    _currentJourneyId = null;
  }
}
