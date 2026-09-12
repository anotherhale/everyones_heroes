import 'package:everyonesheroes/features/hero_story/application/dto/responses/hero_discovery_summary.dart';

final class DiscoverHeroesResponse {
  const DiscoverHeroesResponse({
    required this.items,
    required this.totalCount,
    this.nextOffset,
  });

  final List<HeroDiscoverySummary> items;
  final int totalCount;
  final int? nextOffset;
}
