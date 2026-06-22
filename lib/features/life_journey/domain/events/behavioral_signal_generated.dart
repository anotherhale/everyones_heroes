import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/behavioral_signal_type.dart';

final class BehavioralSignalGenerated extends EventBase {
  BehavioralSignalGenerated({
    required super.aggregateId,
    required this.signalType,
    super.correlationId,
    super.causationId,
  }) : super(aggregateType: 'Journey');

  final BehavioralSignalType signalType;
}
