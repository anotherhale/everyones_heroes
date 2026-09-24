import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Identity for a derived [StoryExperiencePlan] artifact (HS.12.4).
final class StoryExperiencePlanId extends StronglyTypedId {
  const StoryExperiencePlanId(super.value);

  factory StoryExperiencePlanId.generate() {
    return StoryExperiencePlanId(StronglyTypedId.uuid.v4());
  }
}
