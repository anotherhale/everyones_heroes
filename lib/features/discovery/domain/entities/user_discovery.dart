import 'package:everyonesheroes/core/ids/user_discovery_id.dart';
import 'package:everyonesheroes/core/shared_kernel/entity.dart';
import 'package:everyonesheroes/features/discovery/domain/enums/user_discovery_type.dart';

final class UserDiscovery extends Entity<UserDiscoveryId> {
  UserDiscovery({
    required UserDiscoveryId id,
    required this._type,
    required String value,
    required this._confidence,
    required this._discoveredAt,
  }) : _value = value.trim(),
       super(id) {
    if (_value.isEmpty) {
      throw ArgumentError('Discovery value cannot be empty.');
    }

    if (_confidence < 0 || _confidence > 1) {
      throw ArgumentError('Confidence must be between 0.0 and 1.0.');
    }
  }

  final DiscoveryType _type;
  final String _value;
  final double _confidence;
  final DateTime _discoveredAt;

  DiscoveryType get type => _type;
  String get value => _value;
  double get confidence => _confidence;
  DateTime get discoveredAt => _discoveredAt;
}
