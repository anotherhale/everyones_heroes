import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// BCP 47 language tag used across contexts for multilingual content.
final class LanguageCode extends ValueObject {
  LanguageCode(String value) : value = value.trim().toLowerCase() {
    if (this.value.isEmpty) {
      throw ArgumentError('Language code cannot be empty.');
    }

    if (!_pattern.hasMatch(this.value)) {
      throw ArgumentError(
        'Language code must be a valid BCP 47 primary tag '
        '(optionally with region), e.g. "en", "es", "en-us".',
      );
    }
  }

  static final RegExp _pattern = RegExp(r'^[a-z]{2,3}(-[a-z0-9]{2,8})?$');

  final String value;

  @override
  List<Object?> get equalityProps => [value];

  @override
  String toString() => value;
}
