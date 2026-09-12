import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

final class CancelStoryCaptureRequest {
  const CancelStoryCaptureRequest({
    required this.sessionId,
    this.mediaReference,
  });

  final String sessionId;
  final MediaReference? mediaReference;
}
