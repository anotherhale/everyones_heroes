import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/discovery_profile_theme_source.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';

/// Resolves adaptive discovery signals from current Journey understanding and
/// DiscoveryProfile themes.
///
/// Themes (deterministic sorted union):
/// - Reflection.narrativeThemes for the journey
/// - DiscoveryProfile.narrativeThemeIds for the current user (when wired)
///
/// Theme recency: latest Reflection submission time per theme value.
/// DiscoveryProfile-only themes have no Reflection recency entry.
///
/// Inspiration theme ids: DiscoveryProfile themes preserved separately for
/// Today's Experience explanation provenance (D.9). Ranking still uses the
/// union only.
///
/// Patterns: Journey.behaviorPatterns (consume H.2; do not detect here).
abstract interface class ResolveAdaptiveDiscoverySignalsUseCase {
  Future<AdaptiveDiscoverySignals> execute(Journey journey);
}

final class DefaultResolveAdaptiveDiscoverySignalsUseCase
    implements ResolveAdaptiveDiscoverySignalsUseCase {
  const DefaultResolveAdaptiveDiscoverySignalsUseCase({
    required this._reflectionRepository,
    this._discoveryProfileThemeSource =
        const EmptyDiscoveryProfileThemeSource(),
  });

  final ReflectionRepository _reflectionRepository;
  final DiscoveryProfileThemeSource _discoveryProfileThemeSource;

  @override
  Future<AdaptiveDiscoverySignals> execute(Journey journey) async {
    final reflections = await _reflectionRepository.findByJourneyId(
      journey.id,
    );

    final themeValues = <String, NarrativeThemeId>{};
    final themeLastExpressedAt = <String, DateTime>{};

    for (final reflection in reflections) {
      final expressedAt = reflection.submittedAt ?? reflection.createdAt;
      for (final themeId in reflection.narrativeThemes) {
        themeValues.putIfAbsent(themeId.value, () => themeId);
        final previous = themeLastExpressedAt[themeId.value];
        if (previous == null || expressedAt.isAfter(previous)) {
          themeLastExpressedAt[themeId.value] = expressedAt;
        }
      }
    }

    final discoveryThemes =
        await _discoveryProfileThemeSource.currentUserNarrativeThemeIds();
    final inspirationByValue = <String, NarrativeThemeId>{};
    for (final themeId in discoveryThemes) {
      themeValues.putIfAbsent(themeId.value, () => themeId);
      inspirationByValue.putIfAbsent(themeId.value, () => themeId);
    }

    final sortedThemeIds = themeValues.keys.toList()..sort();
    final narrativeThemeIds = [
      for (final value in sortedThemeIds) themeValues[value]!,
    ];

    final sortedInspirationValues = inspirationByValue.keys.toList()..sort();
    final inspirationThemeIds = [
      for (final value in sortedInspirationValues) inspirationByValue[value]!,
    ];

    return AdaptiveDiscoverySignals(
      narrativeThemeIds: narrativeThemeIds,
      behaviorPatterns: List.of(journey.behaviorPatterns),
      themeLastExpressedAt: themeLastExpressedAt,
      inspirationThemeIds: inspirationThemeIds,
    );
  }
}
