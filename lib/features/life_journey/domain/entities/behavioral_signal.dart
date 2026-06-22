import 'package:collection/collection.dart';

import '../enums/behavioral_signal_type.dart';

final class BehavioralSignal {
  BehavioralSignal({required this.type, required this.observedAt});

  final BehavioralSignalType type;

  final DateTime observedAt;

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BehavioralSignal &&
            type == other.type &&
            _equality.equals(observedAt, other.observedAt);
  }

  @override
  int get hashCode => Object.hash(type, _equality.hash(observedAt));
}
