import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/religious_tradition.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/spirituality_category.dart';

/// Story content spirituality/religion metadata.
///
/// Does not assert the Hero's personal religious identity.
final class SpiritualityClassification extends ValueObject {
  SpiritualityClassification({
    required this.category,
    this.tradition,
  }) {
    if (category != SpiritualityCategory.religious && tradition != null) {
      throw ArgumentError(
        'Religious tradition may only be set when category is religious.',
      );
    }
  }

  static final SpiritualityClassification nonSpiritual =
      SpiritualityClassification(category: SpiritualityCategory.nonSpiritual);

  final SpiritualityCategory category;
  final ReligiousTradition? tradition;

  @override
  List<Object?> get equalityProps => [category, tradition];
}
