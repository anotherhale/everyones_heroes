import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_experience_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_detail_screen.dart';

/// Browse discoverable Stories via HS.6 DiscoverStories (HS.7 Slice 1).
class StoryCatalogScreen extends ConsumerWidget {
  const StoryCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storiesAsync = ref.watch(discoverableStoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stories')),
      body: storiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to load stories.'),
              TextButton(
                onPressed: () => ref.invalidate(discoverableStoriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (response) {
          if (response.items.isEmpty) {
            return const Center(
              child: Text(
                'No discoverable stories yet.',
                key: ValueKey('stories-empty'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: response.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final story = response.items[index];
              return ListTile(
                key: ValueKey('story-tile-${story.storyId.value}'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  story.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  [
                    if (story.heroDisplayName != null) story.heroDisplayName!,
                    story.originalLanguage.value.toUpperCase(),
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          StoryDetailScreen(storyId: story.storyId.value),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
