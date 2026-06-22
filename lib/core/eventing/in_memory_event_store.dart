import 'package:everyonesheroes/core/eventing/event_envelope.dart';
import 'package:everyonesheroes/core/eventing/event_store.dart';

final class InMemoryEventStore implements EventStore {
  final List<EventEnvelope> _events = [];

  @override
  Future<void> append(EventEnvelope envelope) async {
    _events.add(envelope);
  }

  @override
  Future<List<EventEnvelope>> allEvents() async {
    return List.unmodifiable(_events);
  }
}
