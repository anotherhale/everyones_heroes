import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/religious_tradition.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/spirituality_classification.dart';

/// Non-authoritative proposed story-content spirituality classification.
///
/// Never asserts Hero personal religion or identity.
final class CandidateSpiritualityClassification extends ValueObject {
  CandidateSpiritualityClassification({
    required this.category,
    this.tradition,
  }) {
    if (category != SpiritualityCategory.religious && tradition != null) {
      throw ArgumentError(
        'Religious tradition may only be set when category is religious.',
      );
    }
  }

  static final CandidateSpiritualityClassification nonSpiritual =
      CandidateSpiritualityClassification(
        category: SpiritualityCategory.nonSpiritual,
      );

  final SpiritualityCategory category;
  final ReligiousTradition? tradition;

  SpiritualityClassification toAuthoritative() {
    return SpiritualityClassification(
      category: category,
      tradition: tradition,
    );
  }

  @override
  List<Object?> get equalityProps => [category, tradition];
}
