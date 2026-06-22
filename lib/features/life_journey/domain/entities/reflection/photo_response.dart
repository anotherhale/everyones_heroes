import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

import 'reflection_response.dart';

final class PhotoResponse extends ReflectionResponse {
  PhotoResponse({required this.photoReference, this.caption}) {
    if (photoReference.trim().isEmpty) {
      throw ArgumentError('Photo reference cannot be empty.');
    }
  }

  /// Storage key, URL, blob id, etc.
  final String photoReference;

  final String? caption;

  @override
  ReflectionResponseType get type => ReflectionResponseType.photo;
}
