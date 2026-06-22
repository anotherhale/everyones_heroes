import 'package:everyonesheroes/core/eventing/event_envelope.dart';

abstract interface class EventStore {
  Future<void> append(EventEnvelope envelope);

  Future<List<EventEnvelope>> allEvents();
}
