import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class ContributionId extends StronglyTypedId {
  const ContributionId(super.value);

  factory ContributionId.generate() {
    return ContributionId(StronglyTypedId.uuid.v4());
  }
}
