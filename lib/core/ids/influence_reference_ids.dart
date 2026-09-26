import 'package:everyonesheroes/core/ids/influence_id.dart';

/// Stable Discovery catalog [InfluenceId] reference values.
///
/// Opaque string IDs for the curated Influence seed catalog.
/// Display names live on Discovery's [InfluenceReferenceCatalog].
abstract final class InfluenceReferenceIds {
  static const InfluenceId rockyBalboa = InfluenceId('rocky-balboa');
  static const InfluenceId davidGoggins = InfluenceId('david-goggins');
  static const InfluenceId aragorn = InfluenceId('aragorn');
  static const InfluenceId michaelJordan = InfluenceId('michael-jordan');
  static const InfluenceId atomicHabits = InfluenceId('atomic-habits');
  static const InfluenceId lordOfTheRings = InfluenceId('lord-of-the-rings');
  static const InfluenceId navySeals = InfluenceId('navy-seals');
  static const InfluenceId malalaYousafzai = InfluenceId('malala-yousafzai');
  static const InfluenceId nelsonMandela = InfluenceId('nelson-mandela');
  static const InfluenceId fredRogers = InfluenceId('fred-rogers');
  static const InfluenceId marieCurie = InfluenceId('marie-curie');
  static const InfluenceId breneBrown = InfluenceId('brene-brown');

  /// All currently seeded Discovery reference Influence IDs.
  static const List<InfluenceId> all = [
    rockyBalboa,
    davidGoggins,
    aragorn,
    michaelJordan,
    atomicHabits,
    lordOfTheRings,
    navySeals,
    malalaYousafzai,
    nelsonMandela,
    fredRogers,
    marieCurie,
    breneBrown,
  ];
}
