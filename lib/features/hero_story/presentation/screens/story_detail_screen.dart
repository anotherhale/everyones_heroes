import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_experience_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_consume_screen.dart';

/// Story experience detail with narrative body (HS.7 Slice 1).
class StoryDetailScreen extends ConsumerWidget {
  const StoryDetailScreen({required this.storyId, super.key});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storyAsync = ref.watch(storyExperienceProvider(storyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: storyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This story is not available.',
              key: ValueKey('story-unavailable'),
            ),
          ),
        ),
        data: (story) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Text(
                story.title,
                key: const ValueKey('story-detail-title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (story.heroDisplayName != null) ...[
                const SizedBox(height: 8),
                Text(
                  story.heroDisplayName!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'NARRATIVE',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                story.narrativeBody,
                key: const ValueKey('story-narrative-body'),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
              if (story.playables.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'AVAILABLE FORMS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (final playable in story.playables)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${playable.formatLabel} · ${playable.languageCode.toUpperCase()}',
                    ),
                  ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                key: const ValueKey('begin-story-consume'),
                onPressed: story.primaryPlayable == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StoryConsumeScreen(
                              storyId: story.storyId.value,
                              representationId:
                                  story.primaryPlayable!.representationId.value,
                            ),
                          ),
                        );
                      },
                child: const Text('Begin story'),
              ),
            ],
          );
        },
      ),
    );
  }
}
