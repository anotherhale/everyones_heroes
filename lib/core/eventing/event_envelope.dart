import 'package:everyonesheroes/core/eventing/domain_event.dart';

final class EventEnvelope {
  final DomainEvent event;

  final String? correlationId;

  final String? causationId;

  const EventEnvelope({
    required this.event,
    this.correlationId,
    this.causationId,
  });
}
