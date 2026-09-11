import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/suitability_level.dart';

/// Content suitability is independent from catalog subject/theme classification
/// and from personalization decisions.
final class ContentSuitability extends ValueObject {
  const ContentSuitability({
    this.profanity = SuitabilityLevel.none,
    this.violence = SuitabilityLevel.none,
    this.sexualContent = SuitabilityLevel.none,
    this.substanceUse = SuitabilityLevel.none,
    this.disturbingContent = SuitabilityLevel.none,
  });

  static const ContentSuitability unmarked = ContentSuitability();

  final SuitabilityLevel profanity;
  final SuitabilityLevel violence;
  final SuitabilityLevel sexualContent;
  final SuitabilityLevel substanceUse;
  final SuitabilityLevel disturbingContent;

  @override
  List<Object?> get equalityProps => [
    profanity,
    violence,
    sexualContent,
    substanceUse,
    disturbingContent,
  ];
}
