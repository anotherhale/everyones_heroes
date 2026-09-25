import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Identity for a derived [MusicRendering] laboratory artifact.
final class MusicRenderingId extends StronglyTypedId {
  const MusicRenderingId(super.value);

  factory MusicRenderingId.generate() {
    return MusicRenderingId(StronglyTypedId.uuid.v4());
  }
}
