/// Lightweight invariant helpers for domain and application layers.
abstract final class Guard {
  static void againstNullOrEmpty(String? value, String name) {
    if (value == null || value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be null or empty');
    }
  }

  static void against(bool condition, String message) {
    if (condition) {
      throw ArgumentError(message);
    }
  }
}
