import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/entities/influence.dart';
import 'package:everyonesheroes/features/discovery/presentation/providers/influence_selection_controller.dart';

/// Discover tab: curated Influence selection for DiscoveryProfile (D.3).
///
/// Hosts the smallest useful "What inspires you?" picker. Does not become a
/// social feed, Hero catalog, or recommendation engine.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  /// Newly chosen Influences not yet persisted on DiscoveryProfile.
  final Set<String> _pendingAdds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final influencesAsync = ref.watch(curatedInfluencesProvider);
    final profileAsync = ref.watch(currentDiscoveryProfileProvider);
    final actionState = ref.watch(influenceSelectionControllerProvider);

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
                          isBusy: actionState.isBusy,
                          errorMessage: actionState.errorMessage,
                          onToggle: (influenceId) {
                            if (profile.containsInfluence(influenceId)) {
                              return;
                            }
                            setState(() {
                              final value = influenceId.value;
                              if (_pendingAdds.contains(value)) {
                                _pendingAdds.remove(value);
                              } else {
                                _pendingAdds.add(value);
                              }
                            });
                          },
                          onSave: () async {
                            final ids = {
                              ...profile.influenceIds.map((id) => id.value),
                              ..._pendingAdds,
                            }.map(InfluenceId.new).toList(growable: false);
                            final ok = await ref
                                .read(
                                  influenceSelectionControllerProvider.notifier,
                                )
                                .save(ids);
                            if (ok && mounted) {
                              setState(_pendingAdds.clear);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
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
    required this.isBusy,
    required this.errorMessage,
    required this.onToggle,
    required this.onSave,
  });

  final List<Influence> influences;
  final DiscoveryProfile profile;
  final Set<String> pendingAdds;
  final bool isBusy;
  final String? errorMessage;
  final ValueChanged<InfluenceId> onToggle;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedOnProfile = influences
        .where((influence) => profile.containsInfluence(influence.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedOnProfile.isNotEmpty) ...[
          Text(
            'Selected inspirations',
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
              for (final influence in selectedOnProfile)
                Chip(
                  key: Key('selected-influence-chip-${influence.id.value}'),
                  avatar: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(influence.canonicalName),
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
            isSelected:
                profile.containsInfluence(influence.id) ||
                pendingAdds.contains(influence.id.value),
            isPersisted: profile.containsInfluence(influence.id),
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
          onPressed: isBusy || pendingAdds.isEmpty ? null : onSave,
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
