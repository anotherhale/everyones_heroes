import 'package:everyonesheroes/core/ids/hero_id.dart';

/// Lists a Hero's discoverable Stories via HS.6 DiscoverStories (HS.7 D5/D6).
final class ListHeroStoriesRequest {
  const ListHeroStoriesRequest({
    required this.heroId,
    this.limit = 20,
    this.offset = 0,
  });

  final HeroId heroId;
  final int limit;
  final int offset;
}
