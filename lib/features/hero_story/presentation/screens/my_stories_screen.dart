import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/presentation/models/owned_story_list_item_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/owner_hero_discoverability_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owned_story_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/owner_hero_discoverability_providers.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/my_hero_profile_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/tell_your_story_screen.dart';

/// Owner-facing Story library (HS.10), Hero discoverability (HS.FG.3),
/// and entry to My Hero Profile (HP.1 / HP.2).
///
/// Hero visibility is a Hero-level concern composed here — not in Story Builder
/// and not coupled to Story publication.
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
              return ListView(
                key: const ValueKey('my-stories-empty-scroll'),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  const _HeroDiscoverabilitySection(),
                  const SizedBox(height: 24),
                  _EmptyMyStories(
                    theme: theme,
                    onTellStory: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TellYourStoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ownedStoriesProvider);
                ref.invalidate(ownerHeroDiscoverabilityProvider);
                await ref.read(ownedStoriesProvider.future);
              },
              child: ListView.separated(
                key: const ValueKey('my-stories-list'),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                itemCount: stories.length + 2,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const _HeroDiscoverabilitySection();
                  }
                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        'Your Stories',
                        key: const ValueKey('my-stories-heading'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final item = stories[index - 2];
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

/// Explicit owner control for Hero catalog discoverability (HS.FG.3).
///
/// Does not publish Stories and does not expose Discovery policy internals.
class _HeroDiscoverabilitySection extends ConsumerWidget {
  const _HeroDiscoverabilitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heroAsync = ref.watch(ownerHeroDiscoverabilityProvider);
    final action = ref.watch(ownerHeroDiscoverabilityControllerProvider);
    final controller =
        ref.read(ownerHeroDiscoverabilityControllerProvider.notifier);

    return heroAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(
            key: ValueKey('hero-discoverability-loading'),
          ),
        ),
      ),
      error: (error, _) => Column(
        key: const ValueKey('hero-discoverability-load-error'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load Hero discoverability.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          TextButton(
            key: const ValueKey('hero-discoverability-retry-load'),
            onPressed: () =>
                ref.invalidate(ownerHeroDiscoverabilityProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
      data: (model) => _HeroDiscoverabilityBody(
        theme: theme,
        model: model,
        isBusy: action.isBusy,
        errorMessage: action.errorMessage,
        onClearError: controller.clearError,
        onOpenMyHeroProfile: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MyHeroProfileScreen(),
            ),
          );
        },
        onMakeDiscoverable: action.isBusy
            ? null
            : () => controller.makeDiscoverable(),
        onMakePrivate:
            action.isBusy ? null : () => controller.makePrivate(),
      ),
    );
  }
}

class _HeroDiscoverabilityBody extends StatelessWidget {
  const _HeroDiscoverabilityBody({
    required this.theme,
    required this.model,
    required this.isBusy,
    required this.errorMessage,
    required this.onClearError,
    required this.onOpenMyHeroProfile,
    required this.onMakeDiscoverable,
    required this.onMakePrivate,
  });

  final ThemeData theme;
  final OwnerHeroDiscoverabilityViewModel model;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onClearError;
  final VoidCallback onOpenMyHeroProfile;
  final VoidCallback? onMakeDiscoverable;
  final VoidCallback? onMakePrivate;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('hero-discoverability-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Hero',
          key: const ValueKey('hero-owner-section-heading'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          model.displayName,
          key: const ValueKey('hero-owner-display-name'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('my-stories-open-hero-profile'),
          onPressed: onOpenMyHeroProfile,
          child: const Text('My Hero Profile'),
        ),
        const SizedBox(height: 20),
        Text(
          'Hero discoverability',
          key: const ValueKey('hero-discoverability-heading'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          model.statusLabel,
          key: const ValueKey('hero-discoverability-status'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          model.statusDescription,
          key: const ValueKey('hero-discoverability-description'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const ValueKey('hero-discoverability-error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('hero-discoverability-dismiss-error'),
              onPressed: onClearError,
              child: const Text('Dismiss'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (model.isDiscoverable)
          OutlinedButton(
            key: const ValueKey('hero-discoverability-make-private'),
            onPressed: onMakePrivate,
            child: Text(isBusy ? 'Updating…' : 'Make Private'),
          )
        else
          FilledButton(
            key: const ValueKey('hero-discoverability-make-discoverable'),
            onPressed: onMakeDiscoverable,
            child: Text(isBusy ? 'Updating…' : 'Make Discoverable'),
          ),
      ],
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
    return Column(
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
