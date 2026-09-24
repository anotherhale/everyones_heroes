import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Identity for a derived [CapturedStoryReading] artifact (HS.12.3).
final class CapturedStoryReadingId extends StronglyTypedId {
  const CapturedStoryReadingId(super.value);

  factory CapturedStoryReadingId.generate() {
    return CapturedStoryReadingId(StronglyTypedId.uuid.v4());
  }
}
