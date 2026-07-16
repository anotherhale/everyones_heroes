import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/discovery/domain/value_objects/discovery_preference_type.dart';

final class DiscoveryPreference extends ValueObject {
  DiscoveryPreference({required this.type, required String value})
    : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError('Preference value cannot be empty.');
    }
  }

  final DiscoveryPreferenceType type;
  final String value;

  @override
  List<Object?> get equalityProps => [type, value];
}
