import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Identity for an [ExperienceRenderManifest] laboratory render artifact.
final class ExperienceRenderManifestId extends StronglyTypedId {
  const ExperienceRenderManifestId(super.value);

  factory ExperienceRenderManifestId.generate() {
    return ExperienceRenderManifestId(StronglyTypedId.uuid.v4());
  }
}
