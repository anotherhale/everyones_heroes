import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class NarrativeThemeId extends StronglyTypedId {
  const NarrativeThemeId(super.value);

  factory NarrativeThemeId.generate() {
    return NarrativeThemeId(StronglyTypedId.uuid.v4());
  }
}
