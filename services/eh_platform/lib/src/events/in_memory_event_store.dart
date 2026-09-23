import 'package:eh_platform/src/events/event_envelope.dart';
import 'package:eh_platform/src/events/event_store.dart';

final class InMemoryEventStore implements EventStore {
  final List<EventEnvelope> _events = [];

  @override
  Future<void> append(EventEnvelope envelope) async {
    _events.add(envelope);
  }

  @override
  Future<List<EventEnvelope>> readAll() async {
    return List<EventEnvelope>.unmodifiable(_events);
  }
}
