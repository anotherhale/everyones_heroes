import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/discovery/application/providers/use_cases/discovery_use_case_providers.dart';
import 'package:everyonesheroes/features/discovery/presentation/providers/inspiring_hero_controller.dart';

/// Private "Inspires me" preference control for a discoverable Hero (D.11).
///
/// Not follow, favorite, friendship, or public endorsement.
class InspiresMeToggle extends ConsumerWidget {
  const InspiresMeToggle({required this.heroId, super.key});

  final String heroId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inspiringAsync = ref.watch(isHeroInspiringMeProvider(heroId));
    final actionState = ref.watch(inspiringHeroControllerProvider);
    final isInspiring = inspiringAsync.value ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterChip(
          key: const Key('inspires-me-toggle'),
          label: Text(
            isInspiring ? 'Inspires me ✓' : 'Inspires me',
            key: Key(
              isInspiring ? 'inspires-me-selected' : 'inspires-me-unselected',
            ),
          ),
          selected: isInspiring,
          onSelected: actionState.isBusy || inspiringAsync.isLoading
              ? null
              : (_) {
                  ref
                      .read(inspiringHeroControllerProvider.notifier)
                      .toggle(HeroId(heroId));
                },
        ),
        if (actionState.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            actionState.errorMessage!,
            key: const Key('inspires-me-error'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
