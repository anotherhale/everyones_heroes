import 'package:everyonesheroes/core/shared_kernel/value_object.dart';

/// Opaque pointer to stored media. Domain does not own storage details.
final class MediaReference extends ValueObject {
  MediaReference(String uri) : uri = uri.trim() {
    if (this.uri.isEmpty) {
      throw ArgumentError('Media reference URI cannot be empty.');
    }
  }

  final String uri;

  @override
  List<Object?> get equalityProps => [uri];

  @override
  String toString() => uri;
}
