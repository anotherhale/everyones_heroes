import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/features/discovery/application/dto/responses/inspiring_hero_summary.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/influence.dart';
import 'package:everyonesheroes/features/discovery/presentation/providers/influence_selection_controller.dart';
import 'package:everyonesheroes/features/discovery/presentation/providers/inspiring_hero_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_profile_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_detail_screen.dart';
import 'package:everyonesheroes/features/life_journey/application/models/inspiration_story_exploration.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/explore_stories_by_inspiration_use_case_provider.dart';

/// Discover tab: curated Influence selection + inspiration-grounded Story
/// exploration (D.3 / D.5 / D.7) and private inspiring Heroes (D.11).
///
/// Hosts "What inspires you?" with editable Current Inspirations, optional
/// "Heroes Who Inspire Me", then Explore Stories connected through
/// NarrativeTheme overlap.
/// Does not become a social feed, recommendation engine, or PersonalizationEngine.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  /// Newly chosen Influences not yet persisted on DiscoveryProfile.
  final Set<String> _pendingAdds = {};

  /// Persisted Influences marked for removal, not yet saved.
  final Set<String> _pendingRemovals = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final influencesAsync = ref.watch(curatedInfluencesProvider);
    final profileAsync = ref.watch(currentDiscoveryProfileProvider);
    final actionState = ref.watch(influenceSelectionControllerProvider);
    final explorationAsync = ref.watch(inspirationGroundedStoriesProvider);

    ref.listen(influenceSelectionControllerProvider, (previous, next) {
      if (next.savedSuccessfully &&
          previous?.savedSuccessfully != true &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your inspirations were saved.'),
            key: Key('influence-selection-saved-snackbar'),
          ),
        );
        ref
            .read(influenceSelectionControllerProvider.notifier)
            .clearSavedFlag();
      }
    });

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Discover',
                  key: const Key('screen-title-discover'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What inspires you?',
                  key: const Key('discover-inspiration-prompt'),
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose people, stories, or works that move you. '
                  'Your choices help shape what you experience next.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                const _HeroesWhoInspireMeSection(),
                const SizedBox(height: 24),
                influencesAsync.when(
                  loading: () => const _CatalogLoading(),
                  error: (_, _) => const _CatalogError(),
                  data: (influences) {
                    if (influences.isEmpty) {
                      return const _CatalogEmpty();
                    }

                    return profileAsync.when(
                      loading: () => const _CatalogLoading(),
                      error: (_, _) => const _CatalogError(),
                      data: (profile) {
                        return _InfluencePicker(
                          influences: influences,
                          profile: profile,
                          pendingAdds: _pendingAdds,
                          pendingRemovals: _pendingRemovals,
                          isBusy: actionState.isBusy,
                          errorMessage: actionState.errorMessage,
                          onToggle: (influenceId) {
                            setState(() {
                              final value = influenceId.value;
                              final isPersisted =
                                  profile.containsInfluence(influenceId);

                              if (isPersisted) {
                                if (_pendingRemovals.contains(value)) {
                                  _pendingRemovals.remove(value);
                                } else {
                                  _pendingRemovals.add(value);
                                  _pendingAdds.remove(value);
                                }
                                return;
                              }

                              if (_pendingAdds.contains(value)) {
                                _pendingAdds.remove(value);
                              } else {
                                _pendingAdds.add(value);
                              }
                            });
                          },
                          onRemovePersisted: (influenceId) {
                            setState(() {
                              _pendingRemovals.add(influenceId.value);
                              _pendingAdds.remove(influenceId.value);
                            });
                          },
                          onSave: () async {
                            final toAdd = _pendingAdds
                                .map(InfluenceId.new)
                                .toList(growable: false);
                            final toRemove = _pendingRemovals
                                .map(InfluenceId.new)
                                .toList(growable: false);
                            final ok = await ref
                                .read(
                                  influenceSelectionControllerProvider.notifier,
                                )
                                .save(
                                  influenceIdsToAdd: toAdd,
                                  influenceIdsToRemove: toRemove,
                                );
                            if (ok && mounted) {
                              setState(() {
                                _pendingAdds.clear();
                                _pendingRemovals.clear();
                              });
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 24),
                _InspirationStoryExplorationSection(
                  explorationAsync: explorationAsync,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Private current-state inspiring Heroes (D.11). Discoverable only; unresolved
/// IDs stay on DiscoveryProfile and are omitted here.
class _HeroesWhoInspireMeSection extends ConsumerWidget {
  const _HeroesWhoInspireMeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heroesAsync = ref.watch(inspiringHeroesProvider);
    final actionState = ref.watch(inspiringHeroControllerProvider);

    return heroesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (heroes) {
        if (heroes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Heroes Who Inspire Me',
              key: const Key('inspiring-heroes-heading'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Private to you — not a follow or public endorsement.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            for (final hero in heroes)
              _InspiringHeroTile(
                hero: hero,
                isBusy: actionState.isBusy,
                onRemove: () {
                  ref
                      .read(inspiringHeroControllerProvider.notifier)
                      .remove(hero.heroId);
                },
                onOpen: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          HeroProfileScreen(heroId: hero.heroId.value),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _InspiringHeroTile extends StatelessWidget {
  const _InspiringHeroTile({
    required this.hero,
    required this.isBusy,
    required this.onRemove,
    required this.onOpen,
  });

  final InspiringHeroSummary hero;
  final bool isBusy;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('inspiring-hero-tile-${hero.heroId.value}'),
      contentPadding: EdgeInsets.zero,
      title: Text(hero.displayName),
      subtitle: hero.biography == null || hero.biography!.isEmpty
          ? null
          : Text(
              hero.biography!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: IconButton(
        key: Key('remove-inspiring-hero-${hero.heroId.value}'),
        tooltip: 'Remove',
        onPressed: isBusy ? null : onRemove,
        icon: const Icon(Icons.close, size: 20),
      ),
      onTap: onOpen,
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: CircularProgressIndicator(
          key: Key('influence-catalog-loading'),
        ),
      ),
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  const _CatalogEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'No curated inspirations are available right now.',
        key: const Key('influence-catalog-empty'),
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'We could not load inspirations. Please try again later.',
        key: const Key('influence-catalog-error'),
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
      ),
    );
  }
}

class _InfluencePicker extends StatelessWidget {
  const _InfluencePicker({
    required this.influences,
    required this.profile,
    required this.pendingAdds,
    required this.pendingRemovals,
    required this.isBusy,
    required this.errorMessage,
    required this.onToggle,
    required this.onRemovePersisted,
    required this.onSave,
  });

  final List<Influence> influences;
  final DiscoveryProfile profile;
  final Set<String> pendingAdds;
  final Set<String> pendingRemovals;
  final bool isBusy;
  final String? errorMessage;
  final ValueChanged<InfluenceId> onToggle;
  final ValueChanged<InfluenceId> onRemovePersisted;
  final VoidCallback onSave;

  bool _isEffectivelySelected(InfluenceId id) {
    if (pendingRemovals.contains(id.value)) {
      return false;
    }
    return profile.containsInfluence(id) || pendingAdds.contains(id.value);
  }

  bool _isCurrentlyPersisted(InfluenceId id) {
    return profile.containsInfluence(id) &&
        !pendingRemovals.contains(id.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentInspirations = influences
        .where((influence) => _isCurrentlyPersisted(influence.id))
        .toList(growable: false);
    final hasPendingChanges =
        pendingAdds.isNotEmpty || pendingRemovals.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentInspirations.isNotEmpty) ...[
          Text(
            'Current Inspirations',
            key: const Key('selected-influences-heading'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final influence in currentInspirations)
                InputChip(
                  key: Key('selected-influence-chip-${influence.id.value}'),
                  label: Text(influence.canonicalName),
                  onDeleted: isBusy
                      ? null
                      : () => onRemovePersisted(influence.id),
                  deleteIcon: Icon(
                    Icons.close,
                    key: Key(
                      'remove-influence-chip-${influence.id.value}',
                    ),
                    size: 18,
                  ),
                  deleteButtonTooltipMessage: 'Remove inspiration',
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'Curated inspirations',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final influence in influences) ...[
          _InfluenceTile(
            influence: influence,
            isSelected: _isEffectivelySelected(influence.id),
            isPersisted: _isCurrentlyPersisted(influence.id),
            onToggle: () => onToggle(influence.id),
          ),
          const SizedBox(height: 12),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            key: const Key('influence-selection-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('save-influences-button'),
          onPressed: isBusy || !hasPendingChanges ? null : onSave,
          child: isBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save inspirations'),
        ),
        const SizedBox(height: 8),
        Text(
          'Return to Home to see how your inspirations may shape '
          "Today's Experience.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _InfluenceTile extends StatelessWidget {
  const _InfluenceTile({
    required this.influence,
    required this.isSelected,
    required this.isPersisted,
    required this.onToggle,
  });

  final Influence influence;
  final bool isSelected;
  final bool isPersisted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = influence.description;

    return Semantics(
      button: true,
      selected: isSelected,
      label: influence.canonicalName,
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: Key('influence-tile-${influence.id.value}'),
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        influence.canonicalName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (isPersisted) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Saved',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// D.7 Explore Stories section — inspiration-grounded, not Reflection-derived.
class _InspirationStoryExplorationSection extends StatelessWidget {
  const _InspirationStoryExplorationSection({
    required this.explorationAsync,
  });

  final AsyncValue<InspirationStoryExploration> explorationAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Explore Stories',
          key: const Key('explore-stories-heading'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stories connected to your inspirations',
          key: const Key('explore-stories-subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        explorationAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                key: Key('explore-stories-loading'),
              ),
            ),
          ),
          error: (_, _) => Text(
            'We could not load related Stories right now.',
            key: const Key('explore-stories-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          data: (exploration) {
            if (!exploration.hasInspirations) {
              return Text(
                'Choose a few inspirations to discover related Stories.',
                key: const Key('explore-stories-empty-no-inspirations'),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              );
            }

            if (exploration.stories.isEmpty) {
              return Text(
                'No Stories match your current inspirations yet.',
                key: const Key('explore-stories-empty-no-matches'),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < exploration.stories.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _InspirationStoryTile(story: exploration.stories[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InspirationStoryTile extends StatelessWidget {
  const _InspirationStoryTile({required this.story});

  final InspirationGroundedStory story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroLabel = story.heroDisplayName;

    return ListTile(
      key: Key('inspiration-story-tile-${story.storyId.value}'),
      contentPadding: EdgeInsets.zero,
      title: Text(
        story.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heroLabel != null && heroLabel.isNotEmpty)
              Text(
                heroLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              story.relevanceLabel,
              key: Key(
                'inspiration-story-provenance-${story.storyId.value}',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StoryDetailScreen(storyId: story.storyId.value),
          ),
        );
      },
    );
  }
}
