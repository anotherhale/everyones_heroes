import 'package:eh_platform/src/events/event_envelope.dart';

abstract interface class EventStore {
  Future<void> append(EventEnvelope envelope);
  Future<List<EventEnvelope>> readAll();
}
