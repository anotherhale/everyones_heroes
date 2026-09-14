import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/reflection_repository.dart';

/// Resolves adaptive discovery signals from current Journey understanding.
///
/// Themes: union of Reflection.narrativeThemes for the journey.
/// Patterns: Journey.behaviorPatterns (consume H.2; do not detect here).
abstract interface class ResolveAdaptiveDiscoverySignalsUseCase {
  Future<AdaptiveDiscoverySignals> execute(Journey journey);
}

final class DefaultResolveAdaptiveDiscoverySignalsUseCase
    implements ResolveAdaptiveDiscoverySignalsUseCase {
  const DefaultResolveAdaptiveDiscoverySignalsUseCase({
    required this._reflectionRepository,
  });

  final ReflectionRepository _reflectionRepository;

  @override
  Future<AdaptiveDiscoverySignals> execute(Journey journey) async {
    final reflections = await _reflectionRepository.findByJourneyId(
      journey.id,
    );

    final themeValues = <String, NarrativeThemeId>{};
    for (final reflection in reflections) {
      for (final themeId in reflection.narrativeThemes) {
        themeValues.putIfAbsent(themeId.value, () => themeId);
      }
    }

    final sortedThemeIds = themeValues.keys.toList()..sort();
    final narrativeThemeIds = [
      for (final value in sortedThemeIds) themeValues[value]!,
    ];

    return AdaptiveDiscoverySignals(
      narrativeThemeIds: narrativeThemeIds,
      behaviorPatterns: List.of(journey.behaviorPatterns),
    );
  }
}
