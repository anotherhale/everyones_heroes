import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Identity for an [ExperienceLabRun] laboratory experiment record.
final class ExperienceLabRunId extends StronglyTypedId {
  const ExperienceLabRunId(super.value);

  factory ExperienceLabRunId.generate() {
    return ExperienceLabRunId(StronglyTypedId.uuid.v4());
  }
}
