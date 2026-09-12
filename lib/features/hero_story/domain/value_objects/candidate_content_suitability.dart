import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/content_suitability.dart';

/// Non-authoritative proposed content suitability.
final class CandidateContentSuitability extends ValueObject {
  const CandidateContentSuitability({
    this.profanity = SuitabilityLevel.none,
    this.violence = SuitabilityLevel.none,
    this.sexualContent = SuitabilityLevel.none,
    this.substanceUse = SuitabilityLevel.none,
    this.disturbingContent = SuitabilityLevel.none,
  });

  static const CandidateContentSuitability unmarked =
      CandidateContentSuitability();

  final SuitabilityLevel profanity;
  final SuitabilityLevel violence;
  final SuitabilityLevel sexualContent;
  final SuitabilityLevel substanceUse;
  final SuitabilityLevel disturbingContent;

  ContentSuitability toAuthoritative() {
    return ContentSuitability(
      profanity: profanity,
      violence: violence,
      sexualContent: sexualContent,
      substanceUse: substanceUse,
      disturbingContent: disturbingContent,
    );
  }

  @override
  List<Object?> get equalityProps => [
    profanity,
    violence,
    sexualContent,
    substanceUse,
    disturbingContent,
  ];
}
