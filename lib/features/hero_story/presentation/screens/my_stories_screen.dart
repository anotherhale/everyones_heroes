import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_list_item_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/tell_your_story_screen.dart';

/// Owner-facing Story library (HS.10). Loads from Story repository only.
class MyStoriesScreen extends ConsumerWidget {
  const MyStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storiesAsync = ref.watch(ownedStoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stories'),
        key: const ValueKey('my-stories-app-bar'),
      ),
      body: SafeArea(
        child: storiesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              key: ValueKey('my-stories-loading'),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unable to load your stories.',
                    key: const ValueKey('my-stories-error'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const ValueKey('my-stories-retry'),
                    onPressed: () => ref.invalidate(ownedStoriesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (stories) {
            if (stories.isEmpty) {
              return _EmptyMyStories(
                theme: theme,
                onTellStory: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TellYourStoryScreen(),
                    ),
                  );
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ownedStoriesProvider);
                await ref.read(ownedStoriesProvider.future);
              },
              child: ListView.separated(
                key: const ValueKey('my-stories-list'),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                itemCount: stories.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Your Stories',
                        key: const ValueKey('my-stories-heading'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final item = stories[index - 1];
                  return _StoryListTile(
                    item: item,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OwnedStoryDetailScreen(
                            storyId: item.storyId.value,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyMyStories extends StatelessWidget {
  const _EmptyMyStories({
    required this.theme,
    required this.onTellStory,
  });

  final ThemeData theme;
  final VoidCallback onTellStory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stories',
            key: const ValueKey('my-stories-empty-title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your experiences can inspire someone else.',
            key: const ValueKey('my-stories-empty-subtitle'),
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          Text(
            "You haven't recorded a story yet.",
            key: const ValueKey('my-stories-empty-body'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('my-stories-empty-tell-story'),
            onPressed: onTellStory,
            icon: const Icon(Icons.mic_none_outlined),
            label: const Text('Tell Your Story'),
          ),
        ],
      ),
    );
  }
}

class _StoryListTile extends StatelessWidget {
  const _StoryListTile({
    required this.item,
    required this.onTap,
  });

  final OwnedStoryListItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      item.recordedLabel,
      if (item.durationLabel != null) item.durationLabel!,
      item.lifecycleLabel,
      item.privacyLabel,
    ].join(' · ');

    return ListTile(
      key: ValueKey('my-story-tile-${item.storyId.value}'),
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        meta,
        key: ValueKey('my-story-meta-${item.storyId.value}'),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
