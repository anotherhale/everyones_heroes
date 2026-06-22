import 'package:everyonesheroes/core/exceptions/validation_exception.dart';

final class Guard {
  const Guard._();

  static void againstNull(Object? value, String parameterName) {
    if (value == null) {
      throw ValidationException('$parameterName cannot be null.');
    }
  }

  static void againstEmpty(String value, String parameterName) {
    if (value.trim().isEmpty) {
      throw ValidationException('$parameterName cannot be empty.');
    }
  }

  static void againstNegative(num value, String parameterName) {
    if (value < 0) {
      throw ValidationException('$parameterName cannot be negative.');
    }
  }

  static void againstInvalid(bool condition, String message) {
    if (condition) {
      throw ValidationException(message);
    }
  }
}
