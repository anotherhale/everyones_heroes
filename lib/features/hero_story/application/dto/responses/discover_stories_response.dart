import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_discovery_summary.dart';

final class DiscoverStoriesResponse {
  const DiscoverStoriesResponse({
    required this.items,
    required this.totalCount,
    this.nextOffset,
  });

  final List<StoryDiscoverySummary> items;
  final int totalCount;
  final int? nextOffset;
}
